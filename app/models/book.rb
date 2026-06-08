class Book < ActiveRecord::Base
  BASE_URL = Rails.env == "development" ? 'http://localhost:3001' : 'https://samooha.sanchaya.net'
  BASE_SEARCH_URL = "#{BASE_URL}/search.json?search="
  IA_SEARCH_URL = 'https://archive.org/advancedsearch.php'
  IA_ITEM_URL = 'https://archive.org/metadata'

  scope :by_author, ->(name) { where(author: name) }
  scope :by_publisher, ->(name) { where(publisher: name) }
  scope :by_library, ->(name) { where(library: name) }
  scope :by_category, ->(name) { where(categories: name) }

  def self.search params
    search_items = params.squish
    full_url = "#{BASE_SEARCH_URL}#{search_items}"
    return parse_url(full_url).body
  end

  def self.wiki_search
    wiki_book_url = 'wiki_books'
    full_url = "#{BASE_URL}/#{wiki_book_url}"
    return parse_url(full_url).body
  end

  def self.categories
    full_url = "#{BASE_URL}/categories"
    return parse_url(full_url).body
  end

  def self.category_books(id)
    full_url = "#{BASE_URL}/categories/#{id}"
    return parse_url(full_url).body
  end

  def self.parse_url(url)
    HTTParty.get(URI.parse(URI.encode(url)), follow_redirects: true)
  end

  def self.capture_wiki_user(book_name,is_account, user_name='', book_id=nil, library=nil)
    wiki_user_url = 'wiki_user_info'
    full_url = "#{BASE_URL}/#{wiki_user_url}?book_name=#{book_name}&&is_account=#{is_account}&&user_name=#{user_name}&&book_id=#{book_id}&&library=#{library}"
    return parse_url(full_url).body
  end

  def self.search_ia(query, page: 1, per_page: 50)
    start = (page - 1) * per_page
    params = {
      q: "collection:JaiGyan AND language:kan AND mediatype:texts -collection:gazetteofindia AND (#{query})",
      fl: 'identifier,title,creator,date,publisher,language,collection,description,year',
      output: 'json',
      rows: per_page,
      start: start,
      sort: 'publicdate desc'
    }

    url = "#{IA_SEARCH_URL}?#{params.to_query}"
    response = parse_url(url)
    data = JSON.parse(response.body)
    docs = data['response']['docs'] || []
    total = data['response']['numFound'] || 0

    books = docs.map { |doc| ia_doc_to_book(doc) }
    { books: books, total: total, page: page, per_page: per_page }
  end

  def self.ia_jai_gyan_books(page: 1, per_page: 50)
    start = (page - 1) * per_page
    params = {
      q: 'collection:JaiGyan AND language:kan AND mediatype:texts -collection:gazetteofindia',
      fl: 'identifier,title,creator,date,publisher,language,collection,description,year',
      output: 'json',
      rows: per_page,
      start: start,
      sort: 'publicdate desc'
    }

    url = "#{IA_SEARCH_URL}?#{params.to_query}"
    response = parse_url(url)
    data = JSON.parse(response.body)
    docs = data['response']['docs'] || []
    total = data['response']['numFound'] || 0

    books = docs.map { |doc| ia_doc_to_book(doc) }
    { books: books, total: total, page: page, per_page: per_page }
  end

  def self.ia_book_details(identifier)
    url = "#{IA_ITEM_URL}/#{identifier}"
    response = parse_url(url)
    JSON.parse(response.body)
  rescue StandardError
    nil
  end

  def self.ia_doc_to_book(doc)
    identifier = doc['identifier']
    creator = Array(doc['creator']).join(', ')
    year_str = doc['year']&.to_s || doc['date']&.[](0..3)
    collection = Array(doc['collection'])
    library = collection.find { |c| c != 'JaiGyan' } || 'JaiGyan'

    {
      'name' => doc['title'],
      'author' => creator,
      'publisher' => doc['publisher'],
      'library' => library,
      'year' => year_str,
      'book_link' => "https://archive.org/details/#{identifier}",
      'archive_url' => "https://archive.org/details/#{identifier}",
      'metadata' => "archive_url:https://archive.org/details/#{identifier}",
      'source_identifier' => identifier
    }
  end

  def self.search_all_cached(query)
    where('name LIKE :q OR author LIKE :q OR publisher LIKE :q', q: "%#{query}%")
  end

  def self.all_authors
    distinct.order(:author).pluck(:author).reject(&:blank?)
  end

  def self.all_publishers
    distinct.order(:publisher).pluck(:publisher).reject(&:blank?)
  end

  def self.all_libraries
    distinct.order(:library).pluck(:library).reject(&:blank?)
  end

  def self.all_categories
    distinct.order(:categories).pluck(:categories).reject(&:blank?)
  end

  def self.author_counts
    where.not(author: [nil, '']).group(:author).order('count_id DESC').count('id')
  end

  def self.publisher_counts
    where.not(publisher: [nil, '']).group(:publisher).order('count_id DESC').count('id')
  end

  def self.library_counts
    where.not(library: [nil, '']).group(:library).order('count_id DESC').count('id')
  end

  def self.category_counts
    where.not(categories: [nil, '']).group(:categories).order('count_id DESC').count('id')
  end
end
