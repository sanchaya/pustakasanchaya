require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'

namespace :ruthumana do
  desc 'Scrape books from store.ruthumana.com via WooCommerce Store API'
  task :scrape => :environment do
    BASE_URL = 'https://store.ruthumana.com'
    API_URL = "#{BASE_URL}/wp-json/wc/store/v1/products"
    PER_PAGE = 100

    all_books = []
    page = 1

    loop do
      url = "#{API_URL}?per_page=#{PER_PAGE}&page=#{page}"
      puts "Fetching page #{page}: #{url}"

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0'

      begin
        response = http.request(request)
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end

      if response.code.to_i != 200
        puts "  HTTP #{response.code}, stopping"
        break
      end

      products = JSON.parse(response.body)
      break if products.empty?

      products.each do |product|
        # Extract author from description text
        desc_html = product['description'] || product['short_description'] || ''
        desc_doc = Nokogiri::HTML.fragment(desc_html)
        desc_text = desc_doc.text.strip

        # Try to extract author - look for common patterns in Kannada book descriptions
        # The description is typically a synopsis, author name is sometimes at the start
        # or marked with patterns like "ಲೇಖಕ:", "ಅನುವಾದ:", etc.
        author = ''
        if desc_text =~ /ಲೇಖಕ[ರ]?\s*[:\s]\s*(.+?)[\n\r,\.]/
          author = $1.strip
        elsif desc_text =~ /ಅನುವಾದ\s*[:\s]\s*(.+?)[\n\r,\.]/
          author = "ಅನು: #{$1.strip}"
        end

        # Extract publisher from description if present
        publisher = 'ಋತುಮಾನ'
        if desc_text =~ /ಪ್ರಕಾಶಕ[ರ]?\s*[:\s]\s*(.+?)[\n\r,\.]/
          publisher = $1.strip
        end

        # Get price (store API returns in minor units)
        price_val = (product.dig('prices', 'price') || '0').to_i / 100.0
        regular_price = (product.dig('prices', 'regular_price') || '0').to_i / 100.0
        display_price = product['on_sale'] ? price_val : regular_price
        price_str = "₹#{'%.2f' % display_price}"

        # Get thumbnail
        thumbnail = ''
        if product['images'] && product['images'].any?
          thumbnail = product['images'][0]['thumbnail'] || product['images'][0]['src'] || ''
        end

        # Get categories
        categories = (product['categories'] || []).map { |c| c['name'] }

        book = {
          'name' => product['name'],
          'author' => author,
          'publisher' => publisher,
          'library' => 'Ruthumana',
          'book_link' => product['permalink'],
          'price' => price_str,
          'thumbnail' => thumbnail,
          'categories' => categories,
          'source_identifier' => "ruthumana_#{product['id']}",
          'year' => nil,
          'archive_url' => nil,
          'sku' => product['sku'] || ''
        }

        all_books << book
      end

      puts "  Got #{products.length} products, total: #{all_books.length}"

      # Check if we have more pages
      total = response['x-wp-total'].to_i rescue 0
      total_pages = response['x-wp-totalpages'].to_i rescue 0

      if page >= total_pages || products.length < PER_PAGE
        puts "  No more pages"
        break
      end

      page += 1
      sleep 0.5
    end

    # Now try to enrich author data from individual product pages
    # The WP REST API (wp/v2/product) doesn't have author fields either,
    # but we can try the HTML product pages for additional metadata
    puts "\n--- Enriching author data from product pages ---"
    books_without_author = all_books.select { |b| b['author'].empty? }
    puts "#{books_without_author.length} books need author enrichment"

    books_without_author.each_with_index do |book, idx|
      url = book['book_link']
      puts "  [#{idx+1}/#{books_without_author.length}] #{book['name']}"

      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = 'Mozilla/5.0'
        response = http.request(request)

        if response.code.to_i == 200
          doc = Nokogiri::HTML(response.body)

          # Check WooCommerce additional info table
          additional_info = doc.at_css('.woocommerce-product-attributes')
          if additional_info
            additional_info.css('tr').each do |row|
              label = row.at_css('th')&.text&.strip&.downcase || ''
              value = row.at_css('td p, td')&.text&.strip || ''
              if label.include?('author') || label.include?('ಲೇಖಕ')
                book['author'] = value
              elsif label.include?('publisher') || label.include?('ಪ್ರಕಾಶಕ')
                book['publisher'] = value
              end
            end
          end

          # Try to extract from og:description or main description
          if book['author'].empty?
            desc = doc.at_css('.woocommerce-product-details__short-description, .woocommerce-Tabs-panel--description')
            if desc
              desc_text = desc.text.strip
              # Look for author patterns
              if desc_text =~ /(?:ಲೇಖಕ[ರ]?|Author)\s*[:\s]\s*(.+?)[\n\r]/i
                book['author'] = $1.strip
              # Check for "ಅನುವಾದ :" pattern
              elsif desc_text =~ /ಅನುವಾದ\s*[:\s]\s*(.+?)[\n\r]/
                book['author'] = "ಅನು: #{$1.strip}"
              # Check first line if it looks like an author name (short line)
              elsif desc_text.lines.first && desc_text.lines.first.strip.length < 60 && desc_text.lines.first =~ /[\u0C80-\u0CFF]/
                # Might be author name - skip if it looks like a description
                first_line = desc_text.lines.first.strip
                unless first_line.length > 40 || first_line.include?('ಬೈಂಡಿಂಗ್') || first_line.include?('ಪುಟ')
                  # book['author'] = first_line  # Too risky, skip
                end
              end
            end
          end

          # Try SKU-based publisher detection
          sku = book['sku'] || ''
          if sku =~ /^B-(\w+)-/
            publisher_code = $1
            case publisher_code
            when 'RUT' then book['publisher'] = 'ಋತುಮಾನ'
            when 'ODU' then book['publisher'] = 'ಓದು ಪ್ರಕಾಶನ'
            when 'GMT' then book['publisher'] = 'ಗಮತ್ ಪ್ರಕಾಶನ'
            when 'VJP' then book['publisher'] = 'ವಿಜ್ಞಾನ ಪುಸ್ತಕ'
            when 'MGU' then book['publisher'] = 'ಮೊಗ್ಗು ಬುಕ್ಸ್'
            end
          end
        end
      rescue => e
        puts "    Error: #{e.message}"
      end

      sleep 0.3
    end

    output_path = Rails.root.join('db', 'ruthumana_books.json')
    File.write(output_path, JSON.pretty_generate(all_books))
    puts "\n=== DONE ==="
    puts "Total books: #{all_books.length}"
    puts "With author: #{all_books.count { |b| !b['author'].empty? }}"
    puts "Saved to: #{output_path}"
  end
end
