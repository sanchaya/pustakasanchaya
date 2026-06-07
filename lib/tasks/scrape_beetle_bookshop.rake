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
  desc 'Scrape Beetle Bookshop Kannada books'
  task :beetle_bookshop => :environment do
    all_books = {}
    base = 'https://beetlebookshop.com'
    
    puts "Beetle Bookshop: Fetching products.json"
    
    begin
      resp = fetch_url("#{base}/products.json")
      
      if resp.code.to_i == 200
        data = JSON.parse(resp.body)
        products = data['products'] || []
        
        puts "Found #{products.length} products"
        
        # Filter for Kannada books
        products.each do |product|
          id = product['id'].to_s
          title = product['title'].to_s.strip
          
          # Skip if not a book or Kannada-related
          next if all_books[id]
          
          # Get price (use first available price)
          price = ''
          if product['variants'] && product['variants'].any?
            variant_price = product['variants'][0]['price']
            price = "₹#{variant_price}" if variant_price
          end
          
          # Get thumbnail
          thumbnail = ''
          if product['image'].is_a?(Hash)
            thumbnail = product['image']['src'] || ''
          end
          
          # Get tags/categories - handle if it's an array
          categories = []
          if product['tags'].is_a?(String)
            categories = product['tags'].split(',').map(&:strip).compact
          elsif product['tags'].is_a?(Array)
            categories = product['tags']
          end
          
          # Extract author from title if possible (format: "Book Title | Author")
          author = ''
          if title.include?(' | ')
            parts = title.split(' | ')
            if parts.length >= 2
              author = parts[1].strip
              title = parts[0].strip
            end
          end
          
          all_books[id] = {
            'name' => title,
            'author' => author,
            'publisher' => 'Beetle Bookshop',
            'library' => 'Beetle Bookshop',
            'book_link' => product['handle'] ? "#{base}/products/#{product['handle']}" : '',
            'price' => price,
            'thumbnail' => thumbnail.start_with?('http') ? thumbnail : "#{base}#{thumbnail}",
            'categories' => categories,
            'source_identifier' => "beetle_#{id}",
            'year' => nil,
            'archive_url' => nil
          }
        end
        
        # Try to get more products from collections
        puts "Beetle Bookshop: Fetching from collections"
        
        collections = [
          'best-kannada-books-to-read',
          'new-arrival'
        ]
        
        collections.each do |collection|
          collection_resp = fetch_url("#{base}/collections/#{collection}/products.json")
          
          if collection_resp.code.to_i == 200
            coll_data = JSON.parse(collection_resp.body)
            coll_products = coll_data['products'] || []
            
            puts "  #{collection}: #{coll_products.length} products"
            
            coll_products.each do |product|
              id = product['id'].to_s
              next if all_books[id]
              
              title = product['title'].to_s.strip
              price = ''
              if product['variants'] && product['variants'].any?
                variant_price = product['variants'][0]['price']
                price = "₹#{variant_price}" if variant_price
              end
              
              thumbnail = ''
              if product['image'].is_a?(Hash)
                thumbnail = product['image']['src'] || ''
              end
              
              categories = []
              if product['tags'].is_a?(String)
                categories = product['tags'].split(',').map(&:strip).compact
              elsif product['tags'].is_a?(Array)
                categories = product['tags']
              end
              
              author = ''
              if title.include?(' | ')
                parts = title.split(' | ')
                if parts.length >= 2
                  author = parts[1].strip
                  title = parts[0].strip
                end
              end
              
              all_books[id] = {
                'name' => title,
                'author' => author,
                'publisher' => 'Beetle Bookshop',
                'library' => 'Beetle Bookshop',
                'book_link' => product['handle'] ? "#{base}/products/#{product['handle']}" : '',
                'price' => price,
                'thumbnail' => thumbnail.start_with?('http') ? thumbnail : "#{base}#{thumbnail}",
                'categories' => categories,
                'source_identifier' => "beetle_#{id}",
                'year' => nil,
                'archive_url' => nil
              }
            end
            
            sleep 0.5
          end
        end
        
      else
        puts "ERROR: Got status #{resp.code}"
      end
      
    rescue => e
      puts "ERROR: #{e.message}"
      puts e.backtrace[0..5]
    end
    
    books = all_books.values
    out = Rails.root.join('db', 'beetle_bookshop_books.json')
    File.write(out, JSON.pretty_generate(books))
    puts "=== Beetle Bookshop DONE: #{books.length} books ==="
  end
end
