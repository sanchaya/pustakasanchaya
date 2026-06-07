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
end
