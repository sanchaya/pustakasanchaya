class Book

  BASE_URL = Rails.env == "development" ? 'http://localhost:3001' : 'https://samooha.sanchaya.net'
  BASE_SEARCH_URL = "#{BASE_URL}/search.json?search="
  IA_SEARCH_URL = 'https://archive.org/advancedsearch.php'
  IA_ITEM_URL = 'https://archive.org/metadata'

  # In-memory cache for book data (loaded once per worker)
  @@jai_gyan_cache = nil
  @@servants_cache = nil
  @@ankita_cache = nil
  @@ruthumana_cache = nil
  @@harivu_cache = nil
  @@kbh_cache = nil
  @@nkp_cache = nil
  @@google_books_cache = nil

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

  def self.load_jai_gyan_cache
    return @@jai_gyan_cache if @@jai_gyan_cache
    file_path = Rails.root.join('db', 'jai_gyan_books.json')
    return [] unless File.exist?(file_path)
    @@jai_gyan_cache = JSON.parse(File.read(file_path))
  end

  def self.search_jai_gyan_cache(query)
    books = load_jai_gyan_cache
    return [] if books.empty?
    query = query.downcase
    books.select do |book|
      book['name'].to_s.downcase.include?(query) ||
        book['author'].to_s.downcase.include?(query) ||
        book['publisher'].to_s.downcase.include?(query)
    end
  end

  def self.load_servants_cache
    return @@servants_cache if @@servants_cache
    file_path = Rails.root.join('db', 'servants_of_knowledge_books.json')
    return [] unless File.exist?(file_path)
    @@servants_cache = JSON.parse(File.read(file_path))
  end

  def self.search_servants_cache(query)
    books = load_servants_cache
    return [] if books.empty?
    query = query.downcase
    books.select do |book|
      book['name'].to_s.downcase.include?(query) ||
        book['author'].to_s.downcase.include?(query) ||
        book['publisher'].to_s.downcase.include?(query)
    end
  end

  def self.load_ankita_cache
    return @@ankita_cache if @@ankita_cache
    file_path = Rails.root.join('db', 'ankita_pustaka_books.json')
    return [] unless File.exist?(file_path)
    @@ankita_cache = JSON.parse(File.read(file_path))
  end

  def self.search_ankita_cache(query)
    books = load_ankita_cache
    return [] if books.empty?
    query = query.downcase
    books.select do |book|
      book['name'].to_s.downcase.include?(query) ||
        book['name_english'].to_s.downcase.include?(query) ||
        book['author'].to_s.downcase.include?(query) ||
        book['publisher'].to_s.downcase.include?(query)
    end
  end

  # --- Ruthumana ---
  def self.load_ruthumana_cache
    return @@ruthumana_cache if @@ruthumana_cache
    file_path = Rails.root.join('db', 'ruthumana_books.json')
    return [] unless File.exist?(file_path)
    @@ruthumana_cache = JSON.parse(File.read(file_path))
  end

  # --- Harivu Books ---
  def self.load_harivu_cache
    return @@harivu_cache if @@harivu_cache
    file_path = Rails.root.join('db', 'harivu_books.json')
    return [] unless File.exist?(file_path)
    @@harivu_cache = JSON.parse(File.read(file_path))
  end

  # --- Kannada Book House ---
  def self.load_kbh_cache
    return @@kbh_cache if @@kbh_cache
    file_path = Rails.root.join('db', 'kannadabookhouse_books.json')
    return [] unless File.exist?(file_path)
    @@kbh_cache = JSON.parse(File.read(file_path))
  end

  # --- Nava Karnataka ---
  def self.load_nkp_cache
    return @@nkp_cache if @@nkp_cache
    file_path = Rails.root.join('db', 'navakarnataka_books.json')
    return [] unless File.exist?(file_path)
    @@nkp_cache = JSON.parse(File.read(file_path))
  end

  # --- Google Books ---
  def self.load_google_books_cache
    return @@google_books_cache if @@google_books_cache
    file_path = Rails.root.join('db', 'google_books.json')
    return [] unless File.exist?(file_path)
    @@google_books_cache = JSON.parse(File.read(file_path))
  end

  def self.search_store_cache(cache_method, query)
    books = send(cache_method)
    return [] if books.empty?
    query = query.downcase
    books.select do |book|
      book['name'].to_s.downcase.include?(query) ||
        book['author'].to_s.downcase.include?(query) ||
        book['publisher'].to_s.downcase.include?(query)
    end
  end

  def self.search_all_cached(query)
    jg = search_jai_gyan_cache(query)
    sok = search_servants_cache(query)
    ankita = search_ankita_cache(query)
    ruthumana = search_store_cache(:load_ruthumana_cache, query)
    harivu = search_store_cache(:load_harivu_cache, query)
    kbh = search_store_cache(:load_kbh_cache, query)
    nkp = search_store_cache(:load_nkp_cache, query)
    google_books = search_store_cache(:load_google_books_cache, query)
    (jg + sok + ankita + ruthumana + harivu + kbh + nkp + google_books).uniq { |b| b['source_identifier'] }
  end

end
