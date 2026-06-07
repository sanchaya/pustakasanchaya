require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'open-uri'

def fetch_url(url, timeout: 15)
  # Handle non-ASCII URLs
  encoded = url.gsub(/[^\x00-\x7F]/) { |c| c.bytes.map { |b| "%%%02X" % b }.join }
  uri = URI.parse(encoded)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = timeout
  http.read_timeout = timeout
  request = Net::HTTP::Get.new(uri.request_uri)
  request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
  http.request(request)
end

namespace :stores do

  # =============================================
  # HARIVU BOOKS (Shopify) - ~5700 products
  # =============================================
  desc 'Scrape books from harivubooks.com (Shopify)'
  task :harivu => :environment do
    all_books = {}
    page = 1

    loop do
      url = "https://harivubooks.com/products.json?limit=250&page=#{page}"
      puts "Harivu: Fetching page #{page}"

      begin
        response = fetch_url(url)
        data = JSON.parse(response.body)
        products = data['products'] || []
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end

      break if products.empty?

      products.each do |p|
        id = p['id'].to_s
        next if all_books[id]

        title = p['title'].to_s.strip
        author = p['vendor'].to_s.strip
        product_type = p['product_type'].to_s.strip
        handle = p['handle'].to_s
        tags = p['tags'] || []

        # Extract publisher from tags
        publisher = ''
        tags.each do |t|
          tl = t.downcase
          if tl.include?('pustaka') || tl.include?('prakashan') || tl.include?('publication')
            publisher = t.strip
            break
          end
        end
        publisher = 'Harivu Books' if publisher.empty?

        # Get price from first variant
        price = ''
        if p['variants'] && p['variants'].any?
          price_val = p['variants'][0]['price'].to_s
          price = "₹#{price_val}"
        end

        # Get thumbnail
        thumbnail = ''
        if p['images'] && p['images'].any?
          thumbnail = p['images'][0]['src'].to_s
        end

        book_link = "https://harivubooks.com/products/#{handle}"

        all_books[id] = {
          'name' => title,
          'author' => author,
          'publisher' => publisher,
          'library' => 'Harivu Books',
          'book_link' => book_link,
          'price' => price,
          'thumbnail' => thumbnail,
          'categories' => [product_type].reject(&:empty?),
          'source_identifier' => "harivu_#{id}",
          'year' => nil,
          'archive_url' => nil
        }
      end

      puts "  Got #{products.length}, total unique: #{all_books.length}"
      break if products.length < 250
      page += 1
      sleep 0.3
    end

    books_array = all_books.values
    output_path = Rails.root.join('db', 'harivu_books.json')
    File.write(output_path, JSON.pretty_generate(books_array))
    puts "=== Harivu DONE: #{books_array.length} books ==="
  end

  # =============================================
  # KANNADA BOOK HOUSE (WooCommerce) - ~3378 products
  # =============================================
  desc 'Scrape books from kannadabookhouse.com (WooCommerce)'
  task :kannadabookhouse => :environment do
    all_books = {}
    page = 1

    loop do
      url = "https://kannadabookhouse.com/wp-json/wc/store/v1/products?per_page=100&page=#{page}"
      puts "KBH: Fetching page #{page}"

      begin
        response = fetch_url(url, timeout: 30)
        break if response.code.to_i != 200
        products = JSON.parse(response.body)
      rescue => e
        puts "  ERROR: #{e.message}"
        break
      end

      break if products.empty?

      products.each do |p|
        id = p['id'].to_s
        next if all_books[id]

        name = p['name'].to_s.strip
        permalink = p['permalink'].to_s.strip

        # Parse description HTML table for Author, Publisher, Binding
        author = ''
        publisher = ''
        binding_type = ''
        language = ''
        desc_html = p['description'] || ''
        if desc_html.include?('<table')
          doc = Nokogiri::HTML.fragment(desc_html)
          doc.css('tr').each do |row|
            cells = row.css('td')
            next unless cells.length >= 2
            label = cells[0].text.strip.downcase
            value = cells[1].text.strip
            if label.include?('author')
              author = value
            elsif label.include?('publisher')
              publisher = value
            elsif label.include?('binding')
              binding_type = value
            elsif label.include?('language')
              language = value
            end
          end
        end

        # Fallback: category name often = author name on this site
        if author.empty? && p['categories'] && p['categories'].any?
          cat_name = p['categories'][0]['name'].to_s.strip
          # Category names on this site are author names
          author = cat_name unless cat_name.downcase.include?('uncat')
        end

        publisher = 'Kannada Book House' if publisher.empty?

        # Price
        price_val = (p.dig('prices', 'price') || '0').to_i / 100.0
        price = "₹#{'%.2f' % price_val}"

        # Thumbnail
        thumbnail = ''
        if p['images'] && p['images'].any?
          thumbnail = p['images'][0]['thumbnail'] || p['images'][0]['src'] || ''
        end

        # Categories
        categories = (p['categories'] || []).map { |c| c['name'] }

        all_books[id] = {
          'name' => name,
          'author' => author,
          'publisher' => publisher,
          'library' => 'Kannada Book House',
          'book_link' => permalink,
          'price' => price,
          'thumbnail' => thumbnail,
          'categories' => categories,
          'source_identifier' => "kbh_#{id}",
          'year' => nil,
          'archive_url' => nil
        }
      end

      puts "  Got #{products.length}, total unique: #{all_books.length}"

      total_pages = response['x-wp-totalpages'].to_i rescue 0
      break if page >= total_pages || products.length < 100
      page += 1
      sleep 0.3
    end

    books_array = all_books.values
    output_path = Rails.root.join('db', 'kannadabookhouse_books.json')
    File.write(output_path, JSON.pretty_generate(books_array))
    puts "=== KBH DONE: #{books_array.length} books ==="
  end

  # =============================================
  # NAVA KARNATAKA (Custom) - category-based
  # =============================================
  desc 'Scrape books from navakarnataka.com'
  task :navakarnataka => :environment do
    all_books = {}
    base = 'https://navakarnataka.com'

    # Get all category URLs
    puts "NKP: Fetching category list"
    begin
      response = fetch_url("#{base}/category")
      html = response.body.force_encoding('UTF-8')
      doc = Nokogiri::HTML(html)
      # Extract links using both Nokogiri and regex fallback
      cat_links = doc.css('a[href*="/book/"]').map { |a| a['href'] }.compact
      if cat_links.empty?
        # Regex fallback
        cat_links = html.scan(/href="(https?:\/\/navakarnataka\.com\/book\/[^"]+)"/).flatten
      end
      if cat_links.empty?
        # Another regex for relative links
        cat_links = html.scan(/href="(\/book\/[^"]+)"/).flatten.map { |h| "#{base}#{h}" }
      end
      cat_links = cat_links.map { |h| h.start_with?('http') ? h : "#{base}#{h}" }.uniq
    rescue => e
      puts "ERROR fetching categories: #{e.message}"
      cat_links = []
    end

    puts "Found #{cat_links.length} categories"

    cat_links.each_with_index do |cat_url, cat_idx|
      cat_name = URI.decode_www_form_component(cat_url.split('/book/').last.to_s)
      puts "NKP [#{cat_idx+1}/#{cat_links.length}]: #{cat_name}"

      page = 1
      loop do
        url = page == 1 ? cat_url : "#{cat_url}?page=#{page}"

      begin
        response = fetch_url(cat_url)
        break if response.code.to_i != 200
        doc = Nokogiri::HTML(response.body)
        rescue => e
          puts "  Error: #{e.message}"
          break
        end

        cards = doc.css('.product-image')
        break if cards.empty?

        new_on_page = 0
        cards.each do |card|
          # Extract from hidden inputs
          slug_el = card.at_css('input[id^="bookSlug"]')
          author_el = card.at_css('input[id^="bookAuthor"]')
          publisher_el = card.at_css('input[id^="bookPublisher"]')
          category_el = card.at_css('input[id^="bookCategory"]')
          lang_el = card.at_css('input[id^="bookLang"]')

          slug = slug_el ? slug_el['value'].to_s.strip : ''
          next if slug.empty?
          next if all_books[slug]

          author = author_el ? author_el['value'].to_s.strip : ''
          publisher = publisher_el ? publisher_el['value'].to_s.strip : ''
          category = category_el ? category_el['value'].to_s.strip : cat_name

          # Title
          title_el = card.at_css('.card-book-title')
          title = title_el ? title_el.text.strip : slug.gsub('-', ' ').capitalize

          # Price
          price_el = card.at_css('.card-price-title')
          price = price_el ? price_el.text.strip.gsub(/[^\d₹.]/, '') : ''
          price = "₹#{price}" unless price.start_with?('₹') || price.empty?

          # Thumbnail
          img_el = card.at_css('img[data-src]') || card.at_css('img[src]')
          thumbnail = ''
          if img_el
            thumbnail = img_el['data-src'] || img_el['src'] || ''
          end

          publisher = 'Nava Karnataka' if publisher.empty?

          book_link = "#{base}/product/#{slug}"

          all_books[slug] = {
            'name' => title,
            'author' => author,
            'publisher' => publisher,
            'library' => 'Nava Karnataka',
            'book_link' => book_link,
            'price' => price,
            'thumbnail' => thumbnail,
            'categories' => [category].reject(&:empty?),
            'source_identifier' => "nkp_#{slug}",
            'year' => nil,
            'archive_url' => nil
          }
          new_on_page += 1
        end

        puts "  Page #{page}: #{cards.length} items, #{new_on_page} new, total: #{all_books.length}"

        # Check for next page
        next_link = doc.at_css('a[rel="next"]') || doc.css('.pagination a').find { |a| a.text.strip == '›' || a.text.strip.include?('Next') }
        break unless next_link

        page += 1
        sleep 0.3
      end
    end

    books_array = all_books.values
    output_path = Rails.root.join('db', 'navakarnataka_books.json')
    File.write(output_path, JSON.pretty_generate(books_array))
    puts "=== NKP DONE: #{books_array.length} books ==="
  end

  # =============================================
  # RUN ALL
  # =============================================
  desc 'Scrape all book stores'
  task :all => [:harivu, :kannadabookhouse, :navakarnataka]
end
