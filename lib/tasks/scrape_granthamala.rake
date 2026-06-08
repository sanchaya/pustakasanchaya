require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'open-uri'

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

def extract_category_from_url(url)
  match = url.match(%r{/shop/([^/]+)/})
  return '' unless match
  raw = match[1].gsub('-', ' ').gsub('_', ' ')
  raw.split.map(&:capitalize).join(' ')
end

def scrape_granthamala_product(url)
  resp = fetch_url(url)
  return nil unless resp.code.to_i == 200

  doc = Nokogiri::HTML(resp.body)

  title = doc.at_css('h1.product_title')&.text&.strip || ''

  attrs = {}
  doc.css('tr.woocommerce-product-attributes-item').each do |row|
    label = row.at_css('th')&.text&.strip
    value = row.at_css('td')&.text&.strip
    attrs[label] = value if label && value
  end

  author = attrs['Author'] || ''

  price_el = doc.at_css('.price ins .woocommerce-Price-amount') || doc.at_css('.price .woocommerce-Price-amount')
  price = price_el ? "₹#{price_el.text.strip.gsub(/[^\d.]/, '')}" : ''

  isbn = attrs['ISBN'] || ''
  year = attrs['Year'] || ''
  pages = attrs['Pages'] || ''
  publisher = attrs['Publisher'] || 'Manohara Grantha Mala'

  og_image = doc.at_css('meta[property="og:image"]')&.attr('content') || ''
  json_ld_image = ''
  doc.css('script[type="application/ld+json"]').each do |script|
    begin
      data = JSON.parse(script.text)
      graph = data['@graph'] || [data]
      graph.each do |item|
        if item['@type'] == 'Product' && item['image']
          json_ld_image = item['image']
          break
        end
      end
    rescue
    end
    break unless json_ld_image.empty?
  end
  thumbnail = json_ld_image unless json_ld_image.empty?
  thumbnail = og_image if thumbnail.to_s.empty?

  json_ld_desc = ''
  doc.css('script[type="application/ld+json"]').each do |script|
    begin
      data = JSON.parse(script.text)
      graph = data['@graph'] || [data]
      graph.each do |item|
        if item['@type'] == 'Product' && item['description']
          json_ld_desc = item['description']
          break
        end
      end
    rescue
    end
    break unless json_ld_desc.empty?
  end
  description = json_ld_desc

  category = extract_category_from_url(url)

  slug = url.match(%r{/([^/]+)/?$})&.[](1) || title.parameterize
  source_identifier = "granthamala_#{slug}"

  {
    'name' => title,
    'author' => author,
    'publisher' => publisher,
    'library' => 'Manohara Grantha Mala',
    'book_link' => url,
    'price' => price,
    'isbn' => isbn,
    'year' => year,
    'pages' => pages,
    'thumbnail' => thumbnail,
    'categories' => category,
    'description' => description,
    'source_identifier' => source_identifier,
    'language' => 'Kannada',
    'source' => 'Granthamala'
  }
end

namespace :scrape do
  desc 'Scrape Granthamala.com Kannada bookstore'
  task :granthamala => :environment do
    sitemap_url = 'https://granthamala.com/wp-sitemap-posts-product-1.xml'
    puts "Fetching sitemap: #{sitemap_url}"
    resp = fetch_url(sitemap_url)
    unless resp.code.to_i == 200
      puts "ERROR: Failed to fetch sitemap (HTTP #{resp.code})"
      exit 1
    end

    doc = Nokogiri::XML(resp.body)
    urls = doc.css('url loc').map(&:text).reject(&:empty?)
    puts "Found #{urls.length} product URLs in sitemap"

    all_books = {}
    errors = []
    urls.each_with_index do |url, idx|
      puts "[#{idx + 1}/#{urls.length}] #{url}"

      begin
        book = scrape_granthamala_product(url)
        if book
          all_books[book['source_identifier']] = book
          puts "  -> #{book['name']} | #{book['author']}"
        else
          puts "  -> FAILED (HTTP error)"
          errors << url
        end
      rescue => e
        puts "  -> ERROR: #{e.message}"
        errors << url
      end

      sleep 0.5 + rand * 0.5
    end

    books = all_books.values
    out = Rails.root.join('db', 'granthamala_books.json')
    File.write(out, JSON.pretty_generate(books))
    puts "=== Granthamala DONE: #{books.length} books scraped ==="
    puts "Errors: #{errors.length}" unless errors.empty?
    errors.each { |e| puts "  #{e}" } unless errors.empty?
  end
end
