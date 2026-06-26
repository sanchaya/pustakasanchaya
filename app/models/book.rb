class Book < ActiveRecord::Base
  BASE_URL = Rails.env == "development" ? 'http://localhost:3001' : 'https://samooha.sanchaya.net'
  BASE_SEARCH_URL = "#{BASE_URL}/search.json?search="
  IA_SEARCH_URL = 'https://archive.org/advancedsearch.php'
  IA_ITEM_URL = 'https://archive.org/metadata'

  has_many :book_stores, dependent: :destroy
  has_many :stores, through: :book_stores

  after_save :clear_search_cache
  after_save :update_slug_columns
  after_destroy :clear_search_cache

  def self.search_cache_version
    Rails.cache.fetch('search/version', expires_in: 1.day) { 1 }
  end

  def self.bump_search_cache
    Rails.cache.write('search/version', search_cache_version + 1, expires_in: 1.day)
  end

  def clear_search_cache
    self.class.bump_search_cache
  end

  scope :by_author, ->(name) { where(author: name) }
  scope :by_publisher, ->(name) { where(publisher: name) }
  scope :by_library, ->(name) { where(library: name) }
  scope :by_category, ->(name) { where("categories = ? OR categories LIKE ?", name, "%- #{escape_like(name)}%") }
  scope :with_stores, -> { includes(:stores) }

  def self.search params
    search_items = params.squish
    # Using a local cache key for search results
    cache_key = "search/local/v#{search_cache_version}/#{Digest::MD5.hexdigest(search_items)}/p1/pp50" 
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do # Local cache for search results
      # Implement local search logic here, querying the local 'books' table
      # MySQL doesn't support ILIKE, use LIKE with LOWER() for case-insensitive search
      search_term = "%#{search_items.downcase}%"
      Book.where('LOWER(name) LIKE ? OR LOWER(author) LIKE ?', search_term, search_term)
          .select(:id, :name, :author, :publisher, :library, :year, :book_link, :archive_url, :thumbnail, :source_identifier, :categories)
          .order(:name) # Default order for local search
          .limit(50) # Limit results to avoid performance issues with broad search
    end
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
    cache_key = "search/ia/v#{search_cache_version}/#{Digest::MD5.hexdigest(query.to_s.downcase.strip)}/p#{page}/pp#{per_page}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
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
    cache_key = "search/local/v#{search_cache_version}/#{Digest::MD5.hexdigest(query.to_s.downcase.strip)}"
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      where('name LIKE :q OR author LIKE :q OR publisher LIKE :q OR library LIKE :q', q: "%#{query}%").to_a
    end
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
    raw = where.not(categories: [nil, '']).distinct.pluck(:categories)
    raw.flat_map { |c| parse_categories_string(c) }.reject(&:blank?).uniq.sort
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
    raw_counts = where.not(categories: [nil, '']).group(:categories).count
    result = Hash.new(0)
    raw_counts.each do |raw_str, count|
      parse_categories_string(raw_str).each { |cat| result[cat] += count }
    end
    result.sort_by { |_, v| -v }.to_h
  end

  def self.escape_like(str)
    str.gsub(/[\\%_]/) { |m| "\\#{m}" }
  end

  def self.parse_categories_string(str)
    return [] if str.blank?
    if str.start_with?("---")
      result = YAML.safe_load(str)
      result.is_a?(Array) ? result.reject(&:blank?).map(&:strip) : []
    else
      [str.strip]
    end
  rescue Psych::SyntaxError
    str.split("\n").grep(/^- /).map { |l| l.sub(/^- /, "").strip }.reject(&:blank?)
  end

  def self.serialize_categories(arr)
    return nil if arr.blank?
    return arr.first if arr.length == 1
    YAML.dump(arr)
  end

  def update_slug_columns
    prev = previous_changes
    changes = {}
    if prev.key?('author') || new_record?
      changes[:author_slug] = author.present? ? SlugHelper.slug_for(author) : nil
    end
    if prev.key?('publisher') || new_record?
      changes[:publisher_slug] = publisher.present? ? SlugHelper.slug_for(publisher) : nil
    end
    update_columns(changes) unless changes.empty?
  end

  def self.update_author_slugs!(author_name)
    slug = SlugHelper.slug_for(author_name)
    where(author: author_name).update_all(author_slug: slug)
  end

  def self.update_publisher_slugs!(publisher_name)
    slug = SlugHelper.slug_for(publisher_name)
    where(publisher: publisher_name).update_all(publisher_slug: slug)
  end

  def self.invalidate_slug_cache!
    keys = %w[
      slug_map:author slug_map:publisher slug_map:category
      slug_pairs:author slug_pairs:publisher slug_pairs:category
    ]
    keys.each { |k| Rails.cache.delete(k) }
  end
end
