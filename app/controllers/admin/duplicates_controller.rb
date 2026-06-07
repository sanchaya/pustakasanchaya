class Admin::DuplicatesController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @suggested_duplicates = []
  end

  def find
    field = params[:field] || 'author'  # author, publisher, or name
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

    # Find the canonical book
    canonical_book = find_book_by_identifier(canonical_id)
    unless canonical_book
      return render json: { error: 'Canonical book not found' }, status: 404
    end

    # Apply corrections to other books (mark them as duplicates)
    source_ids.each do |source_id|
      next if source_id == canonical_id

      book = find_book_by_identifier(source_id)
      next unless book

      # Record the merge
      Correction.record_merge(
        source_ids,
        canonical_id,
        {
          'source_identifier' => source_id,
          'name' => book['name'],
          'author' => book['author'],
          'publisher' => book['publisher']
        },
        current_admin.email,
        "Merged #{source_ids.length} duplicate records"
      )
    end

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
    all_books = load_all_books
    duplicates_by_field = {}

    # Group by field and find similar values
    all_books.each do |book|
      value = normalize_value(book[field])
      next if value.blank?

      # Calculate similarity and group
      key = value
      duplicates_by_field[key] ||= []
      duplicates_by_field[key] << book
    end

    # Return groups with more than one record
    result = []
    duplicates_by_field.each do |key, books|
      next if books.length < 2

      # Calculate similarity score
      similarity_group = {
        field: field,
        value: key,
        count: books.length,
        books: books.map { |b| format_book_for_display(b) },
        similarity_score: calculate_group_similarity(books, field)
      }

      result << similarity_group
    end

    result.sort_by { |g| -g[:count] }
  end

  def normalize_value(value)
    return '' if value.blank?
    value.to_s.strip.downcase.gsub(/[^a-z0-9]/i, '')
  end

  def calculate_group_similarity(books, field)
    return 1.0 if books.length < 2

    # Simple similarity: exact match on normalized value = 1.0
    1.0
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

  def find_book_by_identifier(source_identifier)
    load_all_books.find { |b| b['source_identifier'] == source_identifier }
  end

  def format_book_for_display(book)
    {
      source_identifier: book['source_identifier'],
      name: book['name'],
      author: book['author'],
      publisher: book['publisher'],
      year: book['year'],
      library: book['library']
    }
  end
end
