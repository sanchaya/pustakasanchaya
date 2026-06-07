class Admin::BooksController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @query = params[:q] || ''
    @books = []

    if @query.present?
      @books = Book.search_all_cached(@query)
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
    source_identifier = params[:id]
    @book = find_book_by_identifier(source_identifier)

    unless @book
      render json: { error: 'Book not found' }, status: 404
      return
    end

    # Get existing edits for this book
    @corrections = Correction.edits_for_book(source_identifier)

    render json: {
      book: @book,
      source_identifier: source_identifier,
      corrections: @corrections
    }
  end

  def update
    source_identifier = params[:id]
    field = params[:field]
    new_value = params[:value]

    @book = find_book_by_identifier(source_identifier)
    unless @book
      return render json: { error: 'Book not found' }, status: 404
    end

    old_value = @book[field]

    # Record the edit
    edit = Correction.record_edit(
      source_identifier,
      field,
      old_value,
      new_value,
      current_admin.email,
      params[:description]
    )

    render json: {
      success: true,
      edit: edit,
      message: "#{field.humanize} updated successfully"
    }
  end

  def bulk_edit
    # Show bulk edit interface
  end

  def bulk_update
    field = params[:field]
    find_value = params[:find_value]
    replace_value = params[:replace_value]
    scope = params[:scope] || 'all'  # all, author, publisher, library

    all_books = load_all_books
    affected_books = []

    all_books.each do |book|
      next unless book[field]
      
      should_update = false
      old_value = book[field].to_s

      case scope
      when 'exact'
        should_update = old_value == find_value
      when 'contains'
        should_update = old_value.include?(find_value)
      when 'starts_with'
        should_update = old_value.start_with?(find_value)
      when 'ends_with'
        should_update = old_value.end_with?(find_value)
      else
        should_update = true
      end

      if should_update
        # Record the edit
        edit = Correction.record_edit(
          book['source_identifier'],
          field,
          old_value,
          replace_value,
          current_admin.email,
          "Bulk #{field} update: '#{find_value}' → '#{replace_value}' (#{scope})"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_value: old_value,
          new_value: replace_value,
          edit_id: edit['id']
        }
      end
    end

    render json: {
      success: true,
      affected_count: affected_books.length,
      affected_books: affected_books,
      message: "Updated #{affected_books.length} book(s)"
    }
  end

  def bulk_preview
    field = params[:field]
    find_value = params[:find_value]
    replace_value = params[:replace_value]
    scope = params[:scope] || 'contains'

    all_books = load_all_books
    preview_books = []

    all_books.each do |book|
      next unless book[field]
      
      should_update = false
      old_value = book[field].to_s

      case scope
      when 'exact'
        should_update = old_value == find_value
      when 'contains'
        should_update = old_value.include?(find_value)
      when 'starts_with'
        should_update = old_value.start_with?(find_value)
      when 'ends_with'
        should_update = old_value.end_with?(find_value)
      end

      if should_update
        preview_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          library: book['library'],
          old_value: old_value,
          new_value: replace_value
        }
      end
    end

    render json: {
      success: true,
      preview_count: preview_books.length,
      preview_books: preview_books.first(50),  # Show first 50 in preview
      has_more: preview_books.length > 50
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
    # Load all caches and find the book
    all_books = (
      Book.load_jai_gyan_cache +
      Book.load_servants_cache +
      Book.load_ankita_cache +
      Book.load_ruthumana_cache +
      Book.load_harivu_cache +
      Book.load_kbh_cache +
      Book.load_nkp_cache +
      Book.load_google_books_cache
    )

    all_books.find { |b| b['source_identifier'] == source_identifier }
  end

  def format_book_for_json(book)
    {
      source_identifier: book['source_identifier'],
      name: book['name'],
      title: book['title'],
      author: book['author'],
      publisher: book['publisher'],
      year: book['year'],
      library: book['library'],
      thumbnail: book['thumbnail']
    }
  end

  def load_all_books
    @all_books ||= (
      Book.load_jai_gyan_cache +
      Book.load_servants_cache +
      Book.load_ankita_cache +
      Book.load_ruthumana_cache +
      Book.load_harivu_cache +
      Book.load_kbh_cache +
      Book.load_nkp_cache +
      Book.load_google_books_cache
    )
  end
end
