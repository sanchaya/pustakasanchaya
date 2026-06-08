module BooksHelper

  def archive_url(metadata)
    # if keyword matches for split then result will always be more than 1
    metadata.split('archive_url:').count > 1
  end

# very hard and worst way of fetching the link, should think of changing it
  def wikimedia_url(metadata)
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

  def stats
    {
      'total_books' => Book.count,
      'total_authors' => Book.where.not(author: [nil, '']).distinct.count(:author),
      'total_publishers' => Book.where.not(publisher: [nil, '']).distinct.count(:publisher),
      'total_libraries' => Book.where.not(library: [nil, '']).distinct.count(:library),
      'libraries' => Book.where.not(library: [nil, '']).group(:library).count
    }
  end

  def broken_link?(url)
    return true if url.blank?
    broken_domains = ['dli.gov.in', 'oudl.osmania.ac.in', 'dli.ernet.in', 'osmania']
    broken_domains.any? { |domain| url.include?(domain) }
  end

  STORE_LIBRARIES = ['Ankita Pustaka', 'Ruthumana', 'Harivu Books', 'Kannada Book House', 'Nava Karnataka', 'Bahuroopi', 'Veeraloka Books', 'Total Kannada', 'Sahitya Books', 'Beetle Bookshop'].freeze

  def book_thumbnail_url(book)
    # Use store thumbnail if available
    if book['thumbnail'].present? && STORE_LIBRARIES.include?(book['library'])
      return book['thumbnail']
    end
    archive_url = book['archive_url']
    if archive_url.present? && archive_url.include?('archive.org/details/')
      identifier = archive_url.split('/details/').last
      "https://archive.org/services/img/#{identifier}"
    end
  end

  def store_book?(book)
    STORE_LIBRARIES.include?(book['library']) ||
      book['source_identifier'].to_s =~ /\A(ankita|ruthumana|harivu|kbh|nkp|bahuroopi|veeraloka|totalkannada|sahitya|beetle)_/
  end

  # Keep backward compat
  def ankita_book?(book)
    store_book?(book)
  end

  def year_distribution
    Book.where.not(year: [nil, '', '0'])
        .group(:year)
        .count
        .map { |year, count| { 'year' => year.to_i, 'count' => count } }
        .reject { |e| e['year'] < 1000 || e['year'] > 2030 }
        .sort_by { |e| e['year'] }
  end

  def year_wise_stats
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
      image_tag(url, class: 'book-thumbnail', alt: book['name'], onerror: "this.onerror=null;this.src='#{image_path('pustaka-logo.png')}';this.classList.add('fallback')")
    else
      image_tag('pustaka-logo.png', class: 'book-thumbnail fallback', alt: book['name'])
    end
  end

end
