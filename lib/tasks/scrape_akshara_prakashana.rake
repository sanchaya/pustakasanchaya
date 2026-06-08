require 'json'
require 'net/http'
require 'uri'

def ap_fetch(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 15
  http.read_timeout = 15
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
  http.request(req)
end

namespace :scrape do
  desc 'Scrape aksharaprakashana.com Kannada bookstore'
  task :akshara_prakashana => :environment do
    # Step 1: fetch author categories (parent=69)
    puts "Fetching categories..."
    resp = ap_fetch('https://aksharaprakashana.com/wp-json/wc/store/products/categories?per_page=100')
    cats = JSON.parse(resp.body)
    author_cat_ids = cats.select { |c| c['parent'] == 69 }.map { |c| c['id'] }
    puts "Found #{author_cat_ids.length} author categories"

    # Step 2: fetch all products
    all_products = []
    page = 1
    loop do
      url = "https://aksharaprakashana.com/wp-json/wc/store/products?per_page=100&page=#{page}"
      print "Fetching page #{page}... "
      resp = ap_fetch(url)
      break unless resp.code.to_i == 200
      products = JSON.parse(resp.body)
      break if products.empty?
      all_products.concat(products)
      puts "#{products.length} products"
      page += 1
      sleep 0.3
    end

    puts "\nTotal products: #{all_products.length}"

    # Step 3: transform to our format
    results = all_products.map do |p|
      name = p['name'] || ''

      author_cats = (p['categories'] || []).select { |c| author_cat_ids.include?(c['id']) }
      author = author_cats.map { |c| c['name'] }.first || ''

      price_val = p.dig('prices', 'price').to_i
      price = price_val > 0 ? "\u20b9#{(price_val / 100.0).round(2)}" : ''

      img = (p['images'] || []).first&.dig('src') || ''

      genre_cats = (p['categories'] || []).reject { |c| author_cat_ids.include?(c['id']) || c['parent'] == 0 }
      categories = genre_cats.map { |c| c['name'] }.join(', ')

      {
        'name' => name,
        'author' => author,
        'publisher' => 'Akshara Prakashana',
        'library' => 'Akshara Prakashana',
        'book_link' => p['permalink'] || '',
        'price' => price,
        'isbn' => '',
        'year' => '',
        'pages' => '',
        'thumbnail' => img,
        'categories' => categories,
        'description' => (p['short_description'] || p['description'] || '').gsub(%r{<[^>]+>}, ''),
        'source_identifier' => "akshara_#{p['id']}",
        'language' => 'Kannada',
        'source' => 'AksharaPrakashana'
      }
    end

    out = Rails.root.join('db', 'akshara_prakashana_books.json')
    File.write(out, JSON.pretty_generate(results))
    puts "=== Akshara Prakashana DONE: #{results.length} books scraped ==="
  end
end
