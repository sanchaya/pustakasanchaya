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

    Correction.record_edit(
      source_identifier,
      field,
      old_value,
      new_value,
      current_admin.email,
      params[:description]
    )

    # Persist the change to MySQL
    Book.where(source_identifier: source_identifier).update_all(field => new_value)

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
