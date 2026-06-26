module BooksHelper

  def archive_url(metadata)
    return false if metadata.blank?
    # if keyword matches for split then result will always be more than 1
    metadata.split('archive_url:').count > 1
  end

# very hard and worst way of fetching the link, should think of changing it
  def wikimedia_url(metadata)
    return '' if metadata.blank?
    links = metadata.split("\n")
    @url = ''
    links.each do |meta|
      if meta.include?('archive_url:') and !meta.include?('old_archive_url:')
        @url = meta.split('archive_url:').last
      end
    end 
    return @url
  end

  


  # very hard and worst way of fetching the link, should think of changing it
  def wikisource_url(metadata)
    return '' if metadata.blank?
    links = metadata.split("\n")
    @url = ''
    links.each do |meta|
      if meta.include?('wikisource_url:')
        @url = meta.split('wikisource_url:').last
      end
    end 
    return @url
  end

  def clean_file_name(file_name)
    return file_name + '.djvu'
  end

  def clean_link(url)
    return '' if url.blank?
    url.strip
  end

  def wiki_logo_class(is_present)
    case is_present
    when 'true', true then 'wiki-present'
    when 'false', false then 'wiki-missing'
    else 'wiki-unknown'
    end
  end

  def wiki_logo_title(is_present)
    case is_present
    when 'true', true then 'Present in Wikipedia'
    when 'false', false then 'Not in Wikipedia'
    else 'Unknown'
    end
  end

  def book_cache_key
    max_book_id = Book.maximum(:id)
    max_store_id = Store.maximum(:id)
    book_count = Book.count
    store_count = Store.count
    stats_ver = Book.stats_cache_version
    "books/v4/#{max_book_id}/#{book_count}/#{max_store_id}/#{store_count}/#{stats_ver}"
  end

  def stats
    Rails.cache.fetch("stats/#{book_cache_key}", expires_in: 1.hour) do
      {
        'total_books' => Book.count,
        'total_authors' => Book.where.not(author: [nil, '']).distinct.count(:author),
        'total_publishers' => Book.where.not(publisher: [nil, '']).distinct.count(:publisher),
        'total_categories' => Book.where.not(categories: [nil, '']).distinct.count(:categories),
        'total_libraries' => Book.where.not(library: [nil, '']).distinct.count(:library),
        'total_stores' => Store.active.count,
        'total_store_links' => BookStore.count,
        'stores_with_counts' => Store.active.ordered.joins(:book_stores).group('stores.id', 'stores.name').count('book_stores.id')
      }
    end
  end

  def broken_link?(url)
    return true if url.blank?
    broken_domains = ['dli.gov.in', 'oudl.osmania.ac.in', 'dli.ernet.in']
    begin
      host = URI.parse(url).host
      broken_domains.any? { |domain| host&.include?(domain) }
    rescue URI::InvalidURIError
      false
    end
  end

  STORE_LIBRARIES = [
    'Ankita Pustaka', 'AnkitaPustaka', 'ಅಂಕಿತ ಪುಸ್ತಕ',
    'Ruthumana', 'ಋತುಮಾನ',
    'Harivu Books', 'Harivu', 'ಹರಿವು ಬುಕ್ಸ್',
    'Kannada Book House', 'KannadaBookHouse', 'ಕನ್ನಡ ಬುಕ್ ಹೌಸ್',
    'Nava Karnataka', 'NavaKarnataka', 'ನವಕರ್ನಾಟಕ',
    'Bahuroopi', 'ಬಹುರೂಪಿ',
    'Veeraloka Books', 'Veeraloka', 'ವೀರಲೋಕ ಬುಕ್ಸ್',
    'Total Kannada', 'TotalKannada', 'ಟೋಟಲ್ ಕನ್ನಡ',
    'Sahitya Books', 'Sahitya', 'ಸಾಹಿತ್ಯ ಬುಕ್ಸ್',
    'Beetle Bookshop', 'BeetleBookshop', 'ಬೀಟಲ್ ಬುಕ್‌ಶಾಪ್',
    'Manohara Grantha Mala', 'Granthamala', 'ಮನೋಹರ ಗ್ರಂಥಮಾಲಾ, ಧಾರವಾಡ',
    'Sawanna Enterprises', 'Sawanna', 'ಸಾವಣ್ಣ ಎಂಟರ್‌ಪ್ರೈಸಸ್',
    'Akshara Prakashana', 'AksharaPrakashana', 'ಅಕ್ಷರ ಪ್ರಕಾಶನ',
    'Google Books', 'GoogleBooks', 'ಗೂಗಲ್ ಬುಕ್ಸ್'
  ].freeze

  def valid_thumbnail_url?(url)
    return false if url.blank?
    begin
      uri = URI.parse(url)
      return false if uri.host.blank?
      path = uri.path.to_s
      # Reject URLs that are just domain roots (no specific image path)
      return false if path.blank? || path == '/'
      true
    rescue URI::InvalidURIError
      false
    end
  end

  def book_thumbnail_url(book)
    # Use store thumbnail if available
    if book['thumbnail'].present? && STORE_LIBRARIES.include?(book['library'])
      if valid_thumbnail_url?(book['thumbnail'])
        return book['thumbnail']
      end
    end
    archive_url = book['archive_url']
    if archive_url.present? && archive_url.include?('archive.org/details/')
      identifier = archive_url.split('/details/').last
      return "https://archive.org/services/img/#{identifier}"
    end
    # Fall back to merged_sources for archive.org thumbnails from merged books
    merged = begin
      book['merged_sources']
    rescue
      nil
    end
    if merged.present?
      begin
        sources = JSON.parse(merged)
        sources.each do |source|
          url = source['url'] || ''
          if url.include?('archive.org/details/')
            identifier = url.split('/details/').last
            return "https://archive.org/services/img/#{identifier}"
          end
        end
      rescue JSON::ParserError
      end
    end
    nil
  end

  def fetch_and_cache_thumbnail(book)
    return book if book['thumbnail'].present?
    
    # Get already failed sources to avoid re-fetching
    failed = begin
      JSON.parse(book['thumbnail_failed_sources'] || '[]')
    rescue JSON::ParserError
      []
    end
    
    # Try multiple sources in order
    sources_to_try = [
      { name: 'archive_org', urls: extract_archive_org_identifiers(book) },
      { name: 'google_books', urls: extract_google_books_identifiers(book) },
    ]
    
    sources_to_try.each do |source|
      next if failed.include?(source[:name])
      
      source[:urls].each do |url|
        thumb_url = build_thumbnail_url(source[:name], url)
        next unless thumb_url
        
        # Verify thumbnail exists with HEAD request
        if verify_thumbnail_exists(thumb_url)
          # Cache it
          Book.where(source_identifier: book['source_identifier']).update_all(thumbnail: thumb_url)
          book['thumbnail'] = thumb_url
          return book
        end
      end
      
      # Mark this source as failed for this book
      failed << source[:name]
      Book.where(source_identifier: book['source_identifier']).update_all(thumbnail_failed_sources: failed.to_json)
    end
    
    book
  end
  
  def extract_archive_org_identifiers(book)
    identifiers = []
    if book['archive_url'].present? && book['archive_url'].include?('archive.org/details/')
      identifiers << book['archive_url'].split('/details/').last
    end
    if book['merged_sources'].present?
      begin
        sources = JSON.parse(book['merged_sources'])
        sources.each do |source|
          url = source['url'] || ''
          if url.include?('archive.org/details/')
            identifiers << url.split('/details/').last
          end
        end
      rescue JSON::ParserError
      end
    end
    identifiers.uniq
  end
  
  def extract_google_books_identifiers(book)
    identifiers = []
    # Try to extract ISBN or OCLC from metadata
    if book['metadata'].present?
      book['metadata'].split("\n").each do |line|
        if line.include?('isbn:') || line.include?('ISBN:')
          isbn = line.split(':').last.strip.gsub(/[^0-9X]/, '')
          identifiers << "ISBN:#{isbn}" if isbn.length >= 10
        elsif line.include?('oclc:') || line.include?('OCLC:')
          oclc = line.split(':').last.strip.gsub(/[^0-9]/, '')
          identifiers << "OCLC:#{oclc}" if oclc.present?
        end
      end
    end
    identifiers
  end
  
  def build_thumbnail_url(source_name, identifier)
    case source_name
    when 'archive_org'
      "https://archive.org/services/img/#{identifier}"
    when 'google_books'
      if identifier.start_with?('ISBN:')
        "https://books.google.com/books/content?id=#{identifier.sub('ISBN:', '')}&printsec=frontcover&img=1&zoom=1&source=gbs_api"
      elsif identifier.start_with?('OCLC:')
        "https://covers.openlibrary.org/b/oclc/#{identifier.sub('OCLC:', '')}-L.jpg"
      end
    end
  end
  
  def verify_thumbnail_exists(url)
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 3
      http.read_timeout = 3
      head = http.request_head(uri.path)
      head.code == '200'
    rescue
      false
    end
  end
  
  def fetch_thumbnail_for_book(book)
    return book if book['thumbnail'].present?
    
    failed = begin
      JSON.parse(book['thumbnail_failed_sources'] || '[]')
    rescue JSON::ParserError
      []
    end
    
    # Try Archive.org
    unless failed.include?('archive_org')
      extract_archive_org_identifiers(book).each do |id|
        url = "https://archive.org/services/img/#{id}"
        if verify_thumbnail_exists(url)
          Book.where(source_identifier: book['source_identifier']).update_all(thumbnail: url)
          return url
        end
      end
      failed << 'archive_org'
    end
    
    # Try Google Books
    unless failed.include?('google_books')
      extract_google_books_identifiers(book).each do |id|
        if id.start_with?('ISBN:')
          url = "https://books.google.com/books/content?id=#{id.sub('ISBN:', '')}&printsec=frontcover&img=1&zoom=1&source=gbs_api"
        elsif id.start_with?('OCLC:')
          url = "https://covers.openlibrary.org/b/oclc/#{id.sub('OCLC:', '')}-L.jpg"
        else
          next
        end
        if verify_thumbnail_exists(url)
          Book.where(source_identifier: book['source_identifier']).update_all(thumbnail: url)
          return url
        end
      end
      failed << 'google_books'
    end
    
    # Update failed sources
    Book.where(source_identifier: book['source_identifier']).update_all(thumbnail_failed_sources: failed.to_json)
    nil
  end

  STORE_COLORS = {
    'Ankita Pustaka' => '#E91E63', 'AnkitaPustaka' => '#E91E63', 'ಅಂಕಿತ ಪುಸ್ತಕ' => '#E91E63',
    'Ruthumana' => '#9C27B0', 'ಋತುಮಾನ' => '#9C27B0',
    'Harivu Books' => '#2196F3', 'Harivu' => '#2196F3', 'ಹರಿವು ಬುಕ್ಸ್' => '#2196F3',
    'Kannada Book House' => '#4CAF50', 'KannadaBookHouse' => '#4CAF50', 'ಕನ್ನಡ ಬುಕ್ ಹೌಸ್' => '#4CAF50',
    'Nava Karnataka' => '#FF9800', 'NavaKarnataka' => '#FF9800', 'ನವಕರ್ನಾಟಕ' => '#FF9800',
    'Bahuroopi' => '#795548', 'ಬಹುರೂಪಿ' => '#795548',
    'Veeraloka Books' => '#607D8B', 'Veeraloka' => '#607D8B', 'ವೀರಲೋಕ ಬುಕ್ಸ್' => '#607D8B',
    'Total Kannada' => '#F44336', 'TotalKannada' => '#F44336', 'ಟೋಟಲ್ ಕನ್ನಡ' => '#F44336',
    'Sahitya Books' => '#009688', 'Sahitya' => '#009688', 'ಸಾಹಿತ್ಯ ಬುಕ್ಸ್' => '#009688',
    'Beetle Bookshop' => '#FF5722', 'BeetleBookshop' => '#FF5722', 'ಬೀಟಲ್ ಬುಕ್‌ಶಾಪ್' => '#FF5722',
    'Manohara Grantha Mala' => '#3F51B5', 'Granthamala' => '#3F51B5', 'ಮನೋಹರ ಗ್ರಂಥಮಾಲಾ, ಧಾರವಾಡ' => '#3F51B5',
    'Sawanna Enterprises' => '#8BC34A', 'Sawanna' => '#8BC34A', 'ಸಾವಣ್ಣ ಎಂಟರ್‌ಪ್ರೈಸಸ್' => '#8BC34A',
    'Akshara Prakashana' => '#673AB7', 'AksharaPrakashana' => '#673AB7', 'ಅಕ್ಷರ ಪ್ರಕಾಶನ' => '#673AB7',
    'Google Books' => '#4285F4', 'GoogleBooks' => '#4285F4', 'ಗೂಗಲ್ ಬುಕ್ಸ್' => '#4285F4'
  }.freeze

  def store_logo_for_library(library_name)
    return nil if library_name.blank?
    @_store_logos ||= Store.active.pluck(:name, :logo).each_with_object({}) { |(n, l), h| h[n.downcase] = l }
    @_store_logos[library_name.downcase]
  end

  def store_badge(library_name)
    return nil if library_name.blank?
    color = STORE_COLORS[library_name] || '#6c757d'
    initials = library_name.gsub(/[^A-Za-z]/, '').first(2).upcase
    [color, initials]
  end

  def store_book?(book)
    STORE_LIBRARIES.include?(book['library']) ||
      book['source_identifier'].to_s =~ /\A(ankita|ruthumana|harivu|kbh|nkp|bahuroopi|veeraloka|totalkannada|sahitya|beetle|granthamala|sawanna|akshara)_/
  end

  # Keep backward compat
  def ankita_book?(book)
    store_book?(book)
  end

  def year_distribution
    Rails.cache.fetch("year_distribution/#{book_cache_key}", expires_in: 1.hour) do
      Book.where.not(year: [nil, '', '0'])
          .group(:year)
          .count
          .map { |year, count| { 'year' => year.to_i, 'count' => count } }
          .reject { |e| e['year'] < 1000 || e['year'] > 2030 }
          .sort_by { |e| e['year'] }
    end
  end

  def year_wise_stats
    Rails.cache.fetch("year_wise_stats/#{book_cache_key}", expires_in: 1.hour) do
      rows = Book.connection.select_all(
        "SELECT year, COUNT(*) AS books, COUNT(DISTINCT author) AS authors, COUNT(DISTINCT publisher) AS publishers
         FROM books
         WHERE year IS NOT NULL AND year != '' AND year != '0'
         GROUP BY year"
      )
      rows.map { |r| { 'year' => r['year'].to_i, 'books' => r['books'].to_i, 'authors' => r['authors'].to_i, 'publishers' => r['publishers'].to_i } }
          .reject { |e| e['year'] < 1000 || e['year'] > 2030 }
          .sort_by { |e| e['year'] }
    end
  end

  def decade_groups
    data = year_distribution
    decades = {}
    data.each do |entry|
      d = (entry['year'] / 10) * 10
      decades[d] = (decades[d] || 0) + entry['count']
    end
    max_count = decades.values.max.to_f
    decades.sort_by { |d, _| d }
  end

  def decade_groups_with_authors_publishers
    data = year_wise_stats
    decades = {}
    data.each do |entry|
      year = entry['year'].to_i
      next unless year >= 1900
      d = (year / 10) * 10
      decades[d] ||= { 'books' => 0, 'authors' => Set.new, 'publishers' => Set.new }
      decades[d]['books'] += entry['books']
      # Track unique authors and publishers per decade by using a simple count aggregation
      decades[d][:authors_count] = (decades[d][:authors_count] || 0) + entry['authors']
      decades[d][:publishers_count] = (decades[d][:publishers_count] || 0) + entry['publishers']
    end
    decades.sort_by { |d, _| d }.map do |decade, stats|
      [decade, stats['books'], stats[:authors_count] || 0, stats[:publishers_count] || 0]
    end
  end

  def book_thumbnail_tag(book)
    url = book_thumbnail_url(book)
    if url
      image_tag(url, class: 'book-thumbnail', alt: book['name'], onerror: "this.onerror=null;this.src='#{image_path('sanchaya-logo.png')}';this.classList.add('fallback')")
    else
      image_tag('sanchaya-logo.png', class: 'book-thumbnail fallback', alt: book['name'])
    end
  end

end
