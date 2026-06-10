require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'

def fetch_veeraloka(url, timeout: 20)
  encoded = url.gsub(/[^\x00-\x7F]/) { |c| c.bytes.map { |b| "%%%02X" % b }.join }
  uri = URI.parse(encoded)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = timeout
  http.read_timeout = timeout
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
  http.request(req)
end

namespace :veeraloka do
  desc "Fix publishers for Veeraloka books by scraping detail pages"
  task :fix_publishers => :environment do
    base = 'https://www.veeralokabooks.com'
    
    # Find all books with Veeraloka Books publisher
    books = Book.where(publisher: 'ವೀರಲೋಕ ಬುಕ್ಸ್').where("source_identifier LIKE 'veeraloka_%'")
    puts "Found #{books.count} books with Veeraloka Books publisher\n\n"
    
    updated_count = 0
    failed_count = 0
    total = books.count
    idx = 0
    
    books.find_each do |book|
      idx += 1
      print "\r[#{idx}/#{total}] Processing..."
      
      # Extract book ID from source_identifier (e.g., "veeraloka_123" -> "123")
      book_id = book.source_identifier.gsub('veeraloka_', '')
      book_url = "#{base}/book/#{book_id}"
      
      begin
        resp = fetch_veeraloka(book_url, timeout: 10)
        next unless resp.code.to_i == 200
        
        doc = Nokogiri::HTML(resp.body)
        found_publisher = nil
        
        # Look for publisher in table rows or product detail rows
        doc.css('tr, .product-detail-row').each do |row|
          cells = row.css('td')
          next unless cells.length >= 2
          label = cells[0].text.strip.downcase
          value = cells[1].text.strip
          
          if label.include?('publisher') && value.present?
            found_publisher = value
            break
          end
        end
        
        if found_publisher && found_publisher != 'ವೀರಲೋಕ ಬುಕ್ಸ್'
          book.update_column(:publisher, found_publisher)
          updated_count += 1
        end
      rescue => e
        failed_count += 1
      end
      
      sleep 0.2
    end
    
    puts "\n\n" + "="*60
    puts "VEERALOKA PUBLISHER FIX SUMMARY"
    puts "="*60
    puts "Total books: #{total}"
    puts "Updated: #{updated_count}"
    puts "Failed/No publisher found: #{failed_count}"
    puts "="*60
    
    Book.bump_search_cache
    puts "\nSearch cache updated!"
  end
  
  desc "Check current publisher distribution for Veeraloka books"
  task :check_distribution => :environment do
    books = Book.where("source_identifier LIKE 'veeraloka_%'")
    
    distribution = books.group(:publisher).count.sort_by { |_, count| -count }
    
    puts "Publisher distribution for #{books.count} Veeraloka books:\n\n"
    distribution.each do |publisher, count|
      puts "  #{count.to_s.rjust(5)} books: #{publisher}"
    end
  end
end
