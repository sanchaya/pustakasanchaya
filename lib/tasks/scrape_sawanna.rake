require 'json'
require 'net/http'
require 'uri'

def sawanna_fetch(url, timeout: 15)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = timeout
  http.read_timeout = timeout
  req = Net::HTTP::Get.new(uri.request_uri)
  req['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
  req['Accept'] = 'application/json, text/plain, */*'
  req['Referer'] = 'https://sawannabooks.com/sawanna_new/'
  http.request(req)
end

def sawanna_search(query)
  resp = sawanna_fetch("https://sawannabooks.com/API/searchbooks.php?q=#{URI.encode_www_form_component(query)}")
  return [] unless resp.code.to_i == 200
  data = JSON.parse(resp.body)
  data['books'] || []
end

def sawanna_book_detail(id)
  resp = sawanna_fetch("https://sawannabooks.com/API/new-book-detail.php?id=#{id}")
  return nil unless resp.code.to_i == 200
  data = JSON.parse(resp.body)
  details = data.dig('bookInfo', 'BookDetails')
  details ? details[0] : nil
end

namespace :scrape do
  desc 'Scrape SawannaBooks.com Kannada bookstore'
  task :sawanna => :environment do
    all_books = {}
    search_chars = ('a'..'z').to_a

    search_chars.each do |ch|
      print "Searching '#{ch}'... "
      books = sawanna_search(ch)
      books.each do |b|
        all_books[b['idbooks']] = b
      end
      puts "#{books.length} found (total unique: #{all_books.length})"
      sleep 0.3
    end

    puts "\nFound #{all_books.length} unique books. Fetching details..."

    results = []
    sorted_ids = all_books.keys.sort_by(&:to_i)
    sorted_ids.each_with_index do |id, idx|
      entry = all_books[id]
      print "[#{idx + 1}/#{sorted_ids.length}] #{entry['book_name']}... "

      detail = sawanna_book_detail(id)
      if detail
        image = detail['image'] || ''
        thumbnail = image.start_with?('http') ? image : "https://sawannabooks.com/upload/#{image}"

        results << {
          'name' => detail['book_name'] || entry['book_name'],
          'author' => detail['author_name'] || '',
          'publisher' => detail['publication_name'] || 'Sawanna Enterprises',
          'library' => 'Sawanna Enterprises',
          'book_link' => "https://sawannabooks.com/sawanna_new/#/books",
          'price' => detail['book_price'] ? "\u20b9#{detail['book_price']}" : '',
          'isbn' => detail['isbn'] || detail['isbn_13'] || '',
          'year' => '',
          'pages' => detail['number_of_pages'].to_s,
          'thumbnail' => thumbnail,
          'categories' => detail['subject'] || '',
          'description' => (detail['book_description'] || '').gsub(%r{<[^>]+>}, ''),
          'source_identifier' => "sawanna_#{id}",
          'language' => detail['language_name'] || 'Kannada',
          'source' => 'Sawanna',
          'sku' => detail['sku'] || ''
        }
        puts 'OK'
      else
        puts 'FAILED'
      end

      sleep 0.3
    end

    out = Rails.root.join('db', 'sawanna_books.json')
    File.write(out, JSON.pretty_generate(results))
    puts "\n=== Sawanna DONE: #{results.length} books scraped ==="
  end
end
