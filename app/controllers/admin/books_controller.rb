class Admin::BooksController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @query = params[:q] || ''

    @books = if @query.present?
      books = Book.search_all_cached(@query)
      Book.where(id: books.map(&:id)).includes(:stores).order(:name)
    else
      Book.order(:name).includes(:stores).all
    end

    @books = Kaminari.paginate_array(@books).page(params[:page]).per(20)
  end

  def search
    query = params[:q] || ''
    books = query.present? ? Book.search_all_cached(query) : []

    render json: {
      results: books.map { |b| format_book_for_json(b) }
    }
  end

  def edit
    @book = Book.find(params[:id])

    unless @book
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
    @book = Book.find(params[:id])
    field = params[:field]
    new_value = params[:value]

    unless @book
      return render json: { error: 'Book not found' }, status: 404
    end

    old_value = @book[field]

    Correction.record_edit(
      @book.source_identifier,
      field,
      old_value,
      new_value,
      current_admin.email,
      params[:description]
    )

    Book.where(source_identifier: @book.source_identifier).update_all(field => new_value)
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

    affected.update_all(field => replace_value)
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
    source_ids.each do |source_id|
      next if source_id.to_i == target_id.to_i

      source_book = Book.find_by(id: source_id)
      next unless source_book

      Correction.record_merge(
        source_ids,
        target_id,
        {
          'source_identifier' => source_book.source_identifier,
          'name' => source_book.name,
          'author' => source_book.author,
          'publisher' => source_book.publisher,
          'category' => source_book.categories
        },
        current_admin.email,
        "Merged #{source_ids.length} duplicate book records"
      )

      source_book.destroy
      merged_count += 1
    end

    Book.bump_search_cache

    render json: {
      success: true,
      message: "Successfully merged #{merged_count} book(s)",
      merged_count: merged_count,
      target_book: target_book
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
