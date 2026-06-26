class Admin::BooksController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  SORT_COLUMNS = %w[name author publisher year library].freeze

  def index
    @query = params[:q] || ''
    @sort = params[:sort].presence_in(SORT_COLUMNS) || 'name'
    @direction = params[:direction].presence_in(%w[asc desc]) || 'asc'

    base = if @query.present?
      fixed_query = @query.gsub('ೇ', 'ಿ')
      book_ids = [@query, fixed_query].uniq.flat_map { |q| Book.search_all_cached(q).map(&:id) }.uniq
      Book.where(id: book_ids)
    else
      Book.all
    end

    total = base.count
    page = (params[:page] || 1).to_i
    per_page = 20
    books = base.includes(:stores, :book_stores).order(@sort => @direction).limit(per_page).offset((page - 1) * per_page)
    @books = Kaminari.paginate_array(books, total_count: total).page(params[:page]).per(per_page)
  end

  def search
    query = params[:q] || ''
    if query.present?
      fixed_query = query.gsub('ೇ', 'ಿ')
      books = [query, fixed_query].uniq.flat_map { |q| Book.search_all_cached(q) }
                   .uniq { |b| b.source_identifier }
    else
      books = []
    end

    render json: {
      results: books.map { |b| format_book_for_json(b) }
    }
  end

  def edit
    @book = Book.find_by(id: params[:id])

    if @book.nil?
      render json: { error: 'Book not found' }, status: 404
      return
    end

    @corrections = Correction.edits_for_book(@book.source_identifier)

    render json: {
      book: @book,
      source_identifier: @book.source_identifier,
      corrections: @corrections
    }
  end

  def update
    @book = Book.find_by(id: params[:id])

    if @book.nil?
      return render json: { error: 'Book not found' }, status: 404
    end

    field = params[:field]
    new_value = params[:value]

    old_value = @book[field]

    Correction.record_edit(
      @book.source_identifier,
      field,
      old_value,
      new_value,
      current_admin.email,
      params[:description]
    )

    updates = { field => new_value }
    if field == 'author'
      updates[:author_slug] = new_value.present? ? SlugHelper.slug_for(new_value) : nil
    elsif field == 'publisher'
      updates[:publisher_slug] = new_value.present? ? SlugHelper.slug_for(new_value) : nil
    end
    Book.where(source_identifier: @book.source_identifier).update_all(updates)
    Book.bump_search_cache

    render json: {
      success: true,
      message: "#{field.humanize} updated successfully"
    }
  end

  def bulk_edit
  end

  def bulk_update
    field = params[:field]
    find_value = params[:find_value]
    replace_value = params[:replace_value]
    scope = params[:scope] || 'all'

    scope_condition = case scope
    when 'exact' then { field => find_value }
    when 'contains' then ["#{field} LIKE ?", "%#{find_value}%"]
    when 'starts_with' then ["#{field} LIKE ?", "#{find_value}%"]
    when 'ends_with' then ["#{field} LIKE ?", "%#{find_value}"]
    else nil
    end

    affected = scope_condition ? Book.where(scope_condition) : Book.all
    count = affected.count

    affected.find_each do |book|
      Correction.record_edit(
        book.source_identifier,
        field,
        book[field],
        replace_value,
        current_admin.email,
        "Bulk #{field} update: '#{find_value}' → '#{replace_value}' (#{scope})"
      )
    end

    updates = { field => replace_value }
    if field == 'author'
      updates[:author_slug] = replace_value.present? ? SlugHelper.slug_for(replace_value) : nil
    elsif field == 'publisher'
      updates[:publisher_slug] = replace_value.present? ? SlugHelper.slug_for(replace_value) : nil
    end
    affected.update_all(updates)
    Book.bump_search_cache

    render json: {
      success: true,
      affected_count: count,
      message: "Updated #{count} book(s)"
    }
  end

  def bulk_preview
    field = params[:field]
    find_value = params[:find_value]
    replace_value = params[:replace_value]
    scope = params[:scope] || 'contains'

    scope_condition = case scope
    when 'exact' then { field => find_value }
    when 'contains' then ["#{field} LIKE ?", "%#{find_value}%"]
    when 'starts_with' then ["#{field} LIKE ?", "#{find_value}%"]
    when 'ends_with' then ["#{field} LIKE ?", "%#{find_value}%"]
    else nil
    end

    affected = scope_condition ? Book.where(scope_condition) : Book.all
    preview_books = affected.limit(50).map do |book|
      {
        source_identifier: book.source_identifier,
        title: book.name,
        library: book.library,
        old_value: book[field],
        new_value: replace_value
      }
    end

    total_count = affected.count

    render json: {
      success: true,
      preview_count: total_count,
      preview_books: preview_books,
      has_more: total_count > 50
    }
  end

  def bulk_update_selected
    book_ids = params[:book_ids] || []
    updates = params[:updates] || {}

    if book_ids.empty? || updates.empty?
      return render json: { error: 'No books selected or no fields to update' }, status: 400
    end

    allowed_fields = %w[name author publisher]
    updates = updates.slice(*allowed_fields).select { |_, v| v.present? }

    if updates.empty?
      return render json: { error: 'No valid fields to update' }, status: 400
    end

    affected = Book.where(id: book_ids)
    count = affected.count

    affected.find_each do |book|
      updates.each do |field, new_value|
        old_value = book[field]
        next if old_value == new_value
        Correction.record_edit(
          book.source_identifier,
          field,
          old_value,
          new_value,
          current_admin.email,
          "Bulk edit selected: #{field} updated"
        )
      end
    end

    slug_updates = {}
    if updates.key?('author')
      slug_updates[:author_slug] = updates['author'].present? ? SlugHelper.slug_for(updates['author']) : nil
    end
    if updates.key?('publisher')
      slug_updates[:publisher_slug] = updates['publisher'].present? ? SlugHelper.slug_for(updates['publisher']) : nil
    end
    affected.update_all(updates.merge(slug_updates))
    Book.bump_search_cache

    render json: {
      success: true,
      affected_count: count,
      message: "Updated #{count} book(s)"
    }
  end

  def merge_multiple
    source_ids = params[:source_ids] || []
    target_id = params[:target_id]

    if source_ids.empty? || target_id.blank?
      return render json: { error: 'Please select books to merge and a target book' }, status: 400
    end

    target_book = Book.find_by(id: target_id)
    unless target_book
      return render json: { error: 'Target book not found' }, status: 404
    end

    merged_count = 0
    all_links = []
    all_libraries = Set.new
    all_libraries << target_book.library if target_book.library.present?

    # Include target's own links in merged_sources
    if target_book.book_link.present?
      all_links << { 'url' => target_book.book_link, 'type' => 'book_link', 'library' => target_book.library, 'source_identifier' => target_book.source_identifier }
    end
    if target_book.archive_url.present?
      all_links << { 'url' => target_book.archive_url, 'type' => 'archive_url', 'library' => target_book.library, 'source_identifier' => target_book.source_identifier }
    end

    source_ids.each do |source_id|
      next if source_id.to_i == target_id.to_i

      source_book = Book.find_by(id: source_id)
      next unless source_book

      all_libraries << source_book.library if source_book.library.present?

      # Preserve source book_link
      if source_book.book_link.present?
        all_links << { 'url' => source_book.book_link, 'type' => 'book_link', 'library' => source_book.library, 'source_identifier' => source_book.source_identifier }
      end

      # Preserve source archive_url
      if source_book.archive_url.present?
        all_links << { 'url' => source_book.archive_url, 'type' => 'archive_url', 'library' => source_book.library, 'source_identifier' => source_book.source_identifier }
      end

      # Fill in blank target metadata from source
      target_book.author = source_book.author if target_book.author.blank? && source_book.author.present?
      target_book.publisher = source_book.publisher if target_book.publisher.blank? && source_book.publisher.present?
      target_book.year = source_book.year if target_book.year.blank? && source_book.year.present?
      target_book.thumbnail = source_book.thumbnail if target_book.thumbnail.blank? && source_book.thumbnail.present?
      target_book.archive_url = source_book.archive_url if target_book.archive_url.blank? && source_book.archive_url.present?
      target_book.book_link = source_book.book_link if target_book.book_link.blank? && source_book.book_link.present?

      # Transfer book_stores from source to target
      source_book.book_stores.each do |bs|
        existing = target_book.book_stores.find_by(store_id: bs.store_id)
        unless existing
          BookStore.create!(book_id: target_book.id, store_id: bs.store_id, store_url: bs.store_url, price: bs.price, availability: bs.availability)
        end
      end

      source_book.destroy
      merged_count += 1
    end

    # Update library field to reflect all sources
    target_book.library = all_libraries.to_a.join(', ') if all_libraries.size > 1
    target_book.save!

    # Save all unique links to merged_sources
    all_links = all_links.uniq { |s| s['url'] }
    target_book.update_column(:merged_sources, all_links.to_json)

    Book.bump_search_cache

    render json: {
      success: true,
      message: "Successfully merged #{merged_count} book(s)",
      merged_count: merged_count,
      preserved_links: all_links.length,
      target_book: target_book
    }
  end

  def destroy
    @book = Book.find_by(id: params[:id])

    if @book.nil?
      return render json: { error: 'Book not found' }, status: 404
    end

    title = @book.name
    @book.destroy
    Book.bump_search_cache

    render json: {
      success: true,
      message: "Deleted '#{title}'"
    }
  end

  def fetch_thumbnail
    @book = Book.find_by(id: params[:id])
    
    if @book.nil?
      return render json: { error: 'Book not found' }, status: 404
    end

    force = params[:force] == 'true'
    
    if force
      @book.update_column(:thumbnail_failed_sources, nil)
    end
    
    if @book.thumbnail.present? && !force
      return render json: { success: true, thumbnail: @book.thumbnail, message: 'Thumbnail already exists' }
    end

    # Use the helper to fetch and cache thumbnail (via view_context)
    result = view_context.fetch_thumbnail_for_book(@book)
    
    if result
      @book.reload
      render json: { success: true, thumbnail: @book.thumbnail, message: 'Thumbnail fetched and cached' }
    else
      render json: { success: false, message: 'No thumbnail found (all sources exhausted)' }
    end
  end

  def fetch_thumbnails_bulk
    ids = params[:ids] || []
    return render json: { error: 'No books selected' }, status: 400 if ids.empty?

    books = Book.where(id: ids).where(thumbnail: [nil, ''])
    return render json: { error: 'No books need thumbnails' }, status: 400 if books.empty?

    count = 0
    failed = 0
    
    books.find_each do |book|
      result = view_context.fetch_thumbnail_for_book(book)
      if result
        count += 1
      else
        failed += 1
      end
      sleep(0.1) # Rate limiting
    end

    render json: { success: true, fetched: count, failed: failed }
  end

  def reset_thumbnail_failed
    @book = Book.find_by(id: params[:id])
    
    if @book.nil?
      return render json: { error: 'Book not found' }, status: 404
    end

    @book.update_column(:thumbnail_failed_sources, nil)
    render json: { success: true, message: 'Failed sources reset - will retry on next fetch' }
  end

  def destroy
    @book = Book.find_by(id: params[:id])

    if @book.nil?
      return render json: { error: 'Book not found' }, status: 404
    end

    title = @book.name
    @book.destroy
    Book.bump_search_cache

    render json: {
      success: true,
      message: "Deleted '#{title}'"
    }
  end

  private

  def authorize_admin!
    unless session[:admin_id]
      redirect_to admin_login_path, alert: 'Please login first'
    end
  end

  def current_admin
    @current_admin ||= Admin.find(session[:admin_id]) if session[:admin_id]
  end

  helper_method :current_admin

  def find_book_by_identifier(source_identifier)
    Book.find_by(source_identifier: source_identifier)
  end

  def format_book_for_json(book)
    {
      source_identifier: book.source_identifier,
      name: book.name,
      title: book['title'],
      author: book.author,
      publisher: book.publisher,
      year: book.year,
      library: book.library,
      thumbnail: book.thumbnail
    }
  end
end
