require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'

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
  desc 'Scrape Sahitya Books Kannada store'
  task :sahitya_books => :environment do
    all_books = {}
    base = 'https://sahityabooks.com'
    page = 1
    
    loop do
      url = "#{base}/wp-json/wc/store/v1/products?per_page=100&page=#{page}"
      puts "Sahitya Books: page #{page}"
      
      begin
        resp = fetch_url(url, timeout: 30)
        
        if resp.code.to_i != 200
          puts "  Status: #{resp.code}"
          break
        end
        
        products = JSON.parse(resp.body)
        break if products.empty?
        
        products.each do |p|
          id = p['id'].to_s
          next if all_books[id]
          
          name = p['name'].to_s.strip
          
          # Parse author from title if present (e.g., "Title - Author")
          author = ''
          if name.include?(' - ')
            parts = name.split(' - ')
            if parts.length >= 2
              name = parts[0].strip
              author = parts[1..-1].join(' - ').strip
            end
          end
          
          # Get price
          price = ''
          if p['prices']
            price_val = p['prices']['price'] || p['prices']['regular']
            price = "₹#{price_val}" if price_val
          end
          
          # Get thumbnail
          thumbnail = ''
          if p['images'] && p['images'].any?
            thumbnail = p['images'][0]['src'] || ''
          end
          
          # Get categories
          categories = (p['categories'] || []).map { |c| c['name'] }.compact
          
          all_books[id] = {
            'name' => name,
            'author' => author,
            'publisher' => 'Sahitya Books',
            'library' => 'Sahitya Books',
            'book_link' => p['permalink'] || "#{base}/product/#{p['slug']}",
            'price' => price,
            'thumbnail' => thumbnail.start_with?('http') ? thumbnail : "#{base}#{thumbnail}",
            'categories' => categories,
            'source_identifier' => "sahitya_#{id}",
            'year' => nil,
            'archive_url' => nil
          }
        end
        
        puts "  Got #{products.length}, total: #{all_books.length}"
        
        # Check if there are more pages
        break if products.length < 100
        page += 1
        sleep 0.3
        
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end
    end
    
    books = all_books.values
    out = Rails.root.join('db', 'sahitya_books.json')
    File.write(out, JSON.pretty_generate(books))
    puts "=== Sahitya Books DONE: #{books.length} books ==="
  end
end
