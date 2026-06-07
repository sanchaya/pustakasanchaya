require 'json'
require 'net/http'
require 'uri'

def fetch_url(url, timeout: 20)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = timeout
  http.read_timeout = timeout
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
  http.request(req)
end

namespace :scrape do
  desc 'Scrape Google Books API for Kannada books'
  task :google_books => :environment do
    api_key = 'AIzaSyBGLZhQZkZreD125jsfIBWsd34rMFYVBZU'
    all_books = {}
    base = 'https://www.googleapis.com/books/v1/volumes'
    
    # Search queries for Kannada books (reduced set to minimize API calls)
    queries = [
      { query: 'kannada', label: 'Kannada (general)' },
      { query: 'kannada fiction', label: 'Kannada Fiction' },
      { query: 'kannada literature', label: 'Kannada Literature' },
    ]
    
    queries.each do |q_info|
      start_index = 0
      query_param = q_info[:query]
      query_label = q_info[:label]
      pages_fetched = 0
      max_pages = 5  # Limit to 5 pages (200 results) per query
      
      loop do
        # Build URL with langRestrict for Kannada
        url = "#{base}?q=#{ERB::Util.url_encode(query_param)}&langRestrict=kn&startIndex=#{start_index}&maxResults=40&key=#{api_key}"
        puts "Google Books: #{query_label} (page #{pages_fetched + 1})"
        
        begin
          resp = fetch_url(url, timeout: 30)
          
          if resp.code.to_i != 200
            puts "  Status: #{resp.code}, stopping this query"
            break
          end
          
          data = JSON.parse(resp.body)
          items = data['items'] || []
          total = data['totalItems'] || 0
          
          break if items.empty?
          
          items.each do |item|
            volume_id = item['id'].to_s
            next if all_books[volume_id]
            
            vol_info = item['volumeInfo'] || {}
            
            # Extract basic info
            title = vol_info['title'].to_s.strip
            next if title.empty?
            
            authors = vol_info['authors'] || []
            author = authors.join(', ')
            
            publisher = vol_info['publisher'].to_s.strip
            
            # Extract year from publishedDate (e.g., "2020", "2020-05-15")
            published_date = vol_info['publishedDate'].to_s.strip
            year = nil
            year = published_date.split('-')[0].to_i if published_date.match?(/^\d{4}/)
            
            # Get thumbnail
            thumbnail = ''
            if vol_info['imageLinks']
              thumbnail = vol_info['imageLinks']['thumbnail'] || vol_info['imageLinks']['smallThumbnail'] || ''
            end
            
            # Get info link
            info_link = vol_info['infoLink'] || "https://books.google.com/books?id=#{volume_id}"
            
            # Get description
            description = vol_info['description'].to_s.strip
            
            # Get language
            language = vol_info['language'].to_s.strip
            
            all_books[volume_id] = {
              'name' => title,
              'title' => title,
              'author' => author,
              'authors' => authors,
              'publisher' => publisher,
              'library' => 'Google Books',
              'book_link' => info_link,
              'thumbnail' => thumbnail,
              'source_identifier' => "google_#{volume_id}",
              'year' => year,
              'published_date' => published_date,
              'description' => description,
              'language' => language,
              'page_count' => vol_info['pageCount'],
              'categories' => vol_info['categories'] || [],
              'archive_url' => nil,
              'price' => nil
            }
          end
          
          puts "  Got #{items.length}, total so far: #{all_books.length} (API total: #{total})"
          
          # Stop after max_pages
          pages_fetched += 1
          break if pages_fetched >= max_pages
          
          start_index += 40
          sleep 1.0  # Rate limiting between requests
          
        rescue JSON::ParserError => e
          puts "  JSON ERROR: #{e.message}"
          break
        rescue Timeout::Error
          puts "  TIMEOUT: retrying..."
          sleep 3
          retry
        rescue => e
          puts "  ERROR: #{e.message}"
          break
        end
      end
      
      sleep 2  # Pause between queries
    end
    
    books = all_books.values
    out = Rails.root.join('db', 'google_books.json')
    File.write(out, JSON.pretty_generate(books))
    puts "=== Google Books DONE: #{books.length} books ==="
  end
end
