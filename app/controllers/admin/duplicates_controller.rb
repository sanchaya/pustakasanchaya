class Admin::DuplicatesController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @suggested_duplicates = []
  end

  def find
    field = params[:field] || 'author'
    @suggested_duplicates = find_similar_records(field)

    render json: {
      duplicates: @suggested_duplicates,
      count: @suggested_duplicates.length
    }
  end

  def merge
    source_ids = params[:source_ids] || []
    canonical_id = params[:canonical_id]

    if source_ids.empty? || !canonical_id
      return render json: { error: 'Please select records to merge' }, status: 400
    end

    canonical_book = Book.find_by(source_identifier: canonical_id)
    unless canonical_book
      return render json: { error: 'Canonical book not found' }, status: 404
    end

    source_ids.each do |source_id|
      next if source_id == canonical_id

      book = Book.find_by(source_identifier: source_id)
      next unless book

      Correction.record_merge(
        source_ids,
        canonical_id,
        {
          'source_identifier' => source_id,
          'name' => book.name,
          'author' => book.author,
          'publisher' => book.publisher,
          'category' => book.categories
        },
        current_admin.email,
        "Merged #{source_ids.length} duplicate records"
      )
    end

    Book.bump_search_cache

    render json: {
      success: true,
      message: "Successfully merged #{source_ids.length} records",
      canonical: canonical_book
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

  def find_similar_records(field)
    column = field_to_column(field)
    return [] unless column

    groups = Book.where.not(column => [nil, '']).group(column)
                  .having('count(*) > 1')
                  .order('count_all DESC')
                  .count

    groups.map do |value, count|
      books = Book.where(column => value).limit(50).map { |b| format_book_for_display(b) }
      {
        field: field,
        value: value,
        count: count,
        books: books,
        similarity_score: 1.0
      }
    end
  end

  def field_to_column(field)
    case field
    when 'author' then :author
    when 'publisher' then :publisher
    when 'name' then :name
    when 'category' then :categories
    else nil
    end
  end

  def format_book_for_display(book)
    {
      source_identifier: book.source_identifier,
      name: book.name,
      author: book.author,
      publisher: book.publisher,
      category: book.categories,
      year: book.year,
      library: book.library
    }
  end
end
