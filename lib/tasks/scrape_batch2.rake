require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'

def fetch2(url, timeout: 20)
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

namespace :batch2 do

  # =============================================
  # BAHUROOPI (WooCommerce Store API) - 234 products
  # =============================================
  desc 'Scrape books from bahuroopi.in'
  task :bahuroopi => :environment do
    all_books = {}
    page = 1

    loop do
      url = "https://bahuroopi.in/wp-json/wc/store/v1/products?per_page=100&page=#{page}"
      puts "Bahuroopi: page #{page}"

      begin
        resp = fetch2(url, timeout: 30)
        break if resp.code.to_i != 200
        products = JSON.parse(resp.body)
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end

      break if products.empty?

      products.each do |p|
        id = p['id'].to_s
        next if all_books[id]

        raw_name = p['name'].to_s.strip
        permalink = p['permalink'].to_s.strip

        # Parse author from title: patterns like "TITLE | AUTHOR" or "TITLE by AUTHOR | ಕನ್ನಡ"
        parts = raw_name.split('|').map(&:strip)
        author = ''
        name_kan = ''
        name_eng = ''

        if parts.length >= 3
          # e.g. "Priya Gandhi | ಪ್ರಿಯ ಗಾಂಧಿ | ಚೀ ಜ ರಾಜೀವ"
          name_eng = parts[0]
          name_kan = parts[1]
          author = parts[2]
        elsif parts.length == 2
          # e.g. "TITLE | AUTHOR" or "English Title | Kannada Title"
          # Check if second part has Kannada
          if parts[1] =~ /[\u0C80-\u0CFF]/
            name_eng = parts[0]
            name_kan = parts[1]
          else
            name_eng = parts[0]
            author = parts[1]
          end
        else
          # Check for "by" pattern: "Title by Author"
          if raw_name =~ /^(.+?)\s+by\s+(.+?)(?:\s*[|।]|$)/i
            name_eng = $1.strip
            author = $2.strip
          else
            name_eng = raw_name
          end
        end

        # If still no author, check description
        if author.empty?
          desc_html = p['description'] || ''
          desc_text = Nokogiri::HTML.fragment(desc_html).text.strip
          if desc_text =~ /(?:by|Author|ಲೇಖಕ)\s*[:\s]\s*(.+?)[\n\r\.]/i
            author = $1.strip
          end
        end

        # Use Kannada name as primary if available
        display_name = name_kan.present? ? name_kan : name_eng

        # Publisher from brands
        publisher = ''
        (p['brands'] || []).each do |b|
          publisher = b['name']
          break
        end
        publisher = 'Bahuroopi' if publisher.empty?

        # Price
        price_val = (p.dig('prices', 'price') || '0').to_i / 100.0
        price = "₹#{'%.2f' % price_val}"

        # Thumbnail
        thumbnail = ''
        if p['images'] && p['images'].any?
          thumbnail = p['images'][0]['thumbnail'] || p['images'][0]['src'] || ''
        end

        # Categories (skip discount/meta categories)
        categories = (p['categories'] || []).map { |c| c['name'] }
          .reject { |c| c =~ /discount|latest|best|popular/i }

        all_books[id] = {
          'name' => display_name,
          'name_english' => name_eng,
          'author' => author,
          'publisher' => publisher,
          'library' => 'Bahuroopi',
          'book_link' => permalink,
          'price' => price,
          'thumbnail' => thumbnail,
          'categories' => categories,
          'source_identifier' => "bahuroopi_#{id}",
          'year' => nil,
          'archive_url' => nil
        }
      end

      puts "  Got #{products.length}, total: #{all_books.length}"
      total_pages = resp['x-wp-totalpages'].to_i rescue 0
      break if page >= total_pages || products.length < 100
      page += 1
      sleep 0.3
    end

    books = all_books.values
    out = Rails.root.join('db', 'bahuroopi_books.json')
    File.write(out, JSON.pretty_generate(books))
    puts "=== Bahuroopi DONE: #{books.length} books ==="
  end

  # =============================================
  # VEERALOKA BOOKS (Laravel, HTML scraping) - ~4300 books
  # =============================================
  desc 'Scrape books from veeralokabooks.com'
  task :veeraloka => :environment do
    all_books = {}
    base = 'https://www.veeralokabooks.com'
    page = 1

    loop do
      url = "#{base}/book?page=#{page}"
      puts "Veeraloka: page #{page}"

      begin
        resp = fetch2(url)
        break if resp.code.to_i != 200
        doc = Nokogiri::HTML(resp.body)
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end

      boxes = doc.css('.product-box')
      break if boxes.empty?

      new_count = 0
      boxes.each do |box|
        # Get book link and title
        title_link = box.at_css('.product-detail a[href*="/book/"]')
        next unless title_link

        book_url = title_link['href'].to_s.strip
        slug = book_url.split('/book/').last.to_s.split('?').first
        next if slug.empty? || all_books[slug]

        title = title_link.at_css('h6')&.text&.strip || slug.gsub('-', ' ')

        # Split title: "ಕನ್ನಡ ಶೀರ್ಷಿಕೆ | English Title"
        title_parts = title.split('|').map(&:strip)
        display_name = title_parts[0]

        # Price
        price_el = box.at_css('.product-detail h4')
        price = ''
        if price_el
          # Get the sale price (after del) or regular price
          ins_price = price_el.text.gsub(/[^\d₹.]/, ' ').strip.split.last
          price = "₹#{ins_price}" if ins_price
        end

        # Thumbnail
        img = box.at_css('.front img') || box.at_css('img')
        thumbnail = img ? (img['src'] || '') : ''

        # data-book_id
        btn = box.at_css('[data-book_id]')
        book_id = btn ? btn['data-book_id'] : slug

        all_books[slug] = {
          'name' => display_name,
          'author' => '',
          'publisher' => 'Veeraloka Books',
          'library' => 'Veeraloka Books',
          'book_link' => book_url.start_with?('http') ? book_url : "#{base}#{book_url}",
          'price' => price,
          'thumbnail' => thumbnail.start_with?('http') ? thumbnail : "#{base}#{thumbnail}",
          'categories' => [],
          'source_identifier' => "veeraloka_#{book_id}",
          'year' => nil,
          'archive_url' => nil
        }
        new_count += 1
      end

      puts "  #{boxes.length} items, #{new_count} new, total: #{all_books.length}"
      break if new_count == 0 && page > 1

      # Check for next page
      has_next = doc.css('a[href*="page="]').any? { |a| a['href'].include?("page=#{page + 1}") }
      break unless has_next

      page += 1
      sleep 0.3
    end

    # Enrich with author data from detail pages (sample first 500 to be polite)
    books_no_author = all_books.values.select { |b| b['author'].empty? }
    puts "\nEnriching author data for #{[books_no_author.length, 500].min} books..."

    books_no_author.first(500).each_with_index do |book, idx|
      print "\r  [#{idx+1}/#{[books_no_author.length, 500].min}]"
      begin
        resp = fetch2(book['book_link'], timeout: 10)
        next unless resp.code.to_i == 200
        doc = Nokogiri::HTML(resp.body)

        doc.css('tr, .product-detail-row').each do |row|
          cells = row.css('td')
          next unless cells.length >= 2
          label = cells[0].text.strip.downcase
          value_el = cells[1]
          value = value_el.text.strip

          if label.include?('author')
            book['author'] = value
          elsif label.include?('publisher')
            book['publisher'] = value
          end
        end

        # Also try category from breadcrumb or page
        cat_el = doc.css('.breadcrumb a, .category-tag a').last
        if cat_el
          cat = cat_el.text.strip
          book['categories'] = [cat] unless cat.empty? || cat.downcase == 'home'
        end
      rescue => e
        # skip
      end
      sleep 0.15
    end
    puts

    books = all_books.values
    out = Rails.root.join('db', 'veeraloka_books.json')
    File.write(out, JSON.pretty_generate(books))
    with_author = books.count { |b| !b['author'].empty? }
    puts "=== Veeraloka DONE: #{books.length} books (#{with_author} with author) ==="
  end

  # =============================================
  # TOTAL KANNADA (Custom Omnibus platform) - catalogue-based
  # =============================================
  desc 'Scrape books from totalkannada.com'
  task :totalkannada => :environment do
    all_books = {}
    base = 'https://www.totalkannada.com'

    # Get all catalogue URLs from homepage
    puts "TotalKannada: fetching catalogue list"
    begin
      resp = fetch2("#{base}/")
      doc = Nokogiri::HTML(resp.body)
      cat_links = doc.css('a[href*="/catalogue/"]').map { |a| a['href'] }.compact
        .map { |h| h.start_with?('http') ? h : "#{base}#{h}" }
        .map { |h| h.split('?').first }
        .uniq
    rescue => e
      puts "  ERROR: #{e.message}"
      cat_links = []
    end

    puts "Found #{cat_links.length} catalogues"

    cat_links.each_with_index do |cat_url, idx|
      cat_id = cat_url.split('/catalogue/').last.to_s.gsub('.html', '')
      puts "  [#{idx+1}/#{cat_links.length}] #{cat_id[0..7]}..."

      begin
        resp = fetch2(cat_url)
        next unless resp.code.to_i == 200
        doc = Nokogiri::HTML(resp.body)

        # Get all product links from catalogue page
        product_links = []
        doc.css('a[href*="/products/"]').each do |a|
          href = a['href'].to_s.strip
          next if href.empty?

          # Extract slug and name from href
          # href="/products/UUID.html?ref=catalogue&product-name=Some+Name"
          if href =~ %r{/products/([a-f0-9-]+)\.html\?.*product-name=([^&"]+)}
            slug = $1
            raw_name = URI.decode_www_form_component($2)
            product_links << [slug, raw_name]
          end
        end
        product_links.uniq! { |slug, _| slug }

        new_count = 0
        product_links.each do |slug, pname|
          next if all_books[slug]

          # Parse name: "Book Title | Author Name (Publisher)"
          parts = pname.split('|').map(&:strip)
          title = parts[0] || slug.gsub('-', ' ')
          author = ''
          publisher = 'Total Kannada'

          if parts.length >= 2
            author_part = parts.last
            if author_part =~ /^(.+?)\s*\(([^)]+)\)\s*$/
              author = $1.strip
              publisher = $2.strip
            else
              author = author_part
            end
          end

          all_books[slug] = {
            'name' => title,
            'author' => author,
            'publisher' => publisher,
            'library' => 'Total Kannada',
            'book_link' => "#{base}/products/#{slug}.html",
            'price' => '',
            'thumbnail' => '',
            'categories' => [],
            'source_identifier' => "totalkannada_#{slug}",
            'year' => nil,
            'archive_url' => nil
          }
          new_count += 1
        end

        puts "    #{product_links.length} products, #{new_count} new" if product_links.any?
      rescue => e
        puts "    Error: #{e.message}"
      end
      sleep 0.2
    end

    # Enrich with price/thumbnail from product pages (JSON-LD)
    puts "\nEnriching #{[all_books.length, 300].min} books with price/thumbnail..."
    all_books.values.first(300).each_with_index do |book, idx|
      print "\r  [#{idx+1}/#{[all_books.length, 300].min}]"
      begin
        resp = fetch2(book['book_link'], timeout: 10)
        next unless resp.code.to_i == 200
        html = resp.body

        if html =~ /"@type"\s*:\s*"Product"[^}]+?"price"\s*:\s*(\d+)/
          book['price'] = "₹#{$1}"
        end
        if html =~ /"image"\s*:\s*"([^"]+)"/
          book['thumbnail'] = $1
        end
      rescue
      end
      sleep 0.15
    end
    puts

    books = all_books.values
    out = Rails.root.join('db', 'totalkannada_books.json')
    File.write(out, JSON.pretty_generate(books))
    with_author = books.count { |b| !b['author'].empty? }
    puts "=== TotalKannada DONE: #{books.length} books (#{with_author} with author) ==="
  end

  desc 'Run all batch 2 scrapers'
  task :all => [:bahuroopi, :veeraloka, :totalkannada]
end
