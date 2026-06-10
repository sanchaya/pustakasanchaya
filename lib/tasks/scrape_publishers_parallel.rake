require 'json'
require 'net/http'
require 'nokogiri'
require 'thread'
require 'thread_safe'

namespace :publishers do
  desc "Scrape real publisher data (parallel worker)"
  task :scrape_parallel_source, [:source_name] => :environment do |t, args|
    source_name = args[:source_name].to_sym
    
    sources = {
      sahitya: { file: 'db/sahitya_books.json', portal_name: 'Sahitya Books' },
      veeraloka: { file: 'db/veeraloka_books.json', portal_name: 'Veeraloka Books' },
      navakarnataka: { file: 'db/navakarnataka_books.json', portal_name: 'Navakarnataka' },
      bahuroopi: { file: 'db/bahuroopi_books.json', portal_name: 'Bahuroopi' },
      sawanna: { file: 'db/sawanna_books.json', portal_name: 'Sawanna' }
    }
    
    config = sources[source_name]
    abort("Unknown source: #{source_name}") unless config
    
    puts "\n" + "="*80
    puts "Scraping #{source_name.to_s.upcase}"
    puts "="*80
    
    file_path = Rails.root.join(config[:file])
    abort("File not found: #{file_path}") unless File.exist?(file_path)
    
    data = JSON.parse(File.read(file_path))
    data = [data] unless data.is_a?(Array)
    
    # Filter books with portal name or missing publisher
    books_to_scrape = data.select do |b|
      publisher = b['publisher'].to_s.strip
      publisher.include?(config[:portal_name]) || publisher.empty?
    end
    
    puts "Total books: #{data.length}"
    puts "Books to scrape: #{books_to_scrape.length}"
    
    if books_to_scrape.empty?
      puts "No books need scraping"
      return
    end
    
    # Thread-safe collections
    results = ThreadSafe::Array.new
    failed = ThreadSafe::Array.new
    processed = ThreadSafe::Hash.new { |h, k| h[k] = 0 }
    
    # Worker thread pool
    num_workers = 4
    queue = Queue.new
    
    books_to_scrape.each { |book| queue << book }
    num_workers.times { queue << nil }
    
    workers = num_workers.times.map do
      Thread.new do
        while book = queue.pop
          break unless book
          
          result = scrape_book_page(book['book_link'], source_name)
          
          if result && result[:publisher].present?
            results << {
              name: book['name'],
              original_publisher: book['publisher'],
              scraped_publisher: result[:publisher],
              book_link: book['book_link']
            }
          else
            failed << { name: book['name'], book_link: book['book_link'] }
          end
          
          processed[:count] += 1
          if processed[:count] % 20 == 0
            puts "\r  Processed: #{processed[:count]}/#{books_to_scrape.length}"
          end
          
          sleep(0.3) # Rate limit
        end
      end
    end
    
    workers.each(&:join)
    
    puts "\nResults:"
    puts "  Successfully scraped: #{results.length}"
    puts "  Failed: #{failed.length}"
    
    # Save results
    output_file = Rails.root.join("tmp/scraped_publishers_#{source_name}.json")
    File.write(output_file, JSON.pretty_generate({
      source: source_name.to_s,
      total_books: data.length,
      books_to_scrape: books_to_scrape.length,
      successfully_scraped: results.length,
      failed: failed.length,
      scraped_data: results,
      failed_books: failed
    }))
    
    puts "  Results saved to: #{output_file}"
  end
  
  def scrape_book_page(url, source_name)
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 10
      http.open_timeout = 10
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      
      response = http.request(request)
      return nil unless response.code == '200'
      
      doc = Nokogiri::HTML(response.body)
      
      case source_name.to_s
      when 'sahitya'
        scrape_sahitya(doc)
      when 'veeraloka'
        scrape_veeraloka(doc)
      when 'navakarnataka'
        scrape_navakarnataka(doc)
      when 'bahuroopi'
        scrape_bahuroopi(doc)
      when 'sawanna'
        scrape_sawanna(doc)
      end
    rescue => e
      nil
    end
  end
  
  def scrape_sahitya(doc)
    publisher = extract_publisher(doc, %w[
      .product-meta .product-publisher
      .book-publisher
      [itemprop="publisher"]
      th:contains("Publisher") + td
    ])
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_veeraloka(doc)
    publisher = extract_publisher(doc, %w[
      .product-meta-publisher
      [data-attribute*="publisher"]
      th:contains("Publisher") + td
    ])
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_navakarnataka(doc)
    publisher = extract_publisher(doc, %w[
      .product-publisher
      .publisher
      [itemprop="publisher"]
      th:contains("Publisher") + td
    ])
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_bahuroopi(doc)
    publisher = extract_publisher(doc, %w[
      .product-publisher
      .publisher-name
      [itemprop="publisher"]
      th:contains("Publisher") + td
    ])
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_sawanna(doc)
    publisher = extract_publisher(doc, %w[
      .product-publisher
      .publisher
      [itemprop="publisher"]
      th:contains("Publisher") + td
    ])
    { publisher: publisher } if publisher.present?
  end
  
  def extract_publisher(doc, selectors)
    selectors.each do |selector|
      text = doc.css(selector).text.strip
      return text if text.present? && text.length < 150 && text.length > 2
    end
    nil
  end
end
