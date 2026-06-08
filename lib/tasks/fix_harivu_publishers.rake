require 'json'
require 'net/http'
require 'uri'
require 'timeout'

def fetch_harivu(url, timeout: 20)
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

def extract_publisher_from_page(body)
  html = body.force_encoding('UTF-8')
  # Only match subtitle that contains "Publisher" text
  rx = /class="product__text inline-richtext subtitle"[^>]*?>(.*?)<\/div>/m
  match = html.match(rx)
  return nil unless match
  text = match[1].gsub(/<[^>]+>/, '').strip
  return nil unless text =~ /Publisher/i
  if text =~ /Publisher\s*[-–—:]\s*(.+)/i
    result = $1.strip
    # Reject false matches like prices
    return nil if result =~ /^Regular price/i || result =~ /^₹|Rs\.?|Price/i
    result
  else
    nil
  end
end

namespace :harivu do
  desc 'Fix incorrect publisher names from harivubooks.com product pages'
  task fix_publishers: :environment do
    # First sync JSON from DB so we have a snapshot
    file_path = Rails.root.join('db', 'harivu_books.json')
    unless File.exist?(file_path)
      puts "ERROR: harivu_books.json not found"
      exit 1
    end

    books = JSON.parse(File.read(file_path))
    wrong_publishers = ['Harivu Books', 'Harivu Books Publication', 'Harivu', 'Regular price']
    remaining = books.select { |b| wrong_publishers.include?(b['publisher'].to_s.strip) }
    total_fixed_in_run = 0

    # Also check DB for books already fixed by previous partial run
    books.each do |book|
      db_book = Book.find_by(source_identifier: book['source_identifier'])
      if db_book && !wrong_publishers.include?(db_book.publisher.to_s.strip)
        book['publisher'] = db_book.publisher
      end
    end

    # Re-check remaining after syncing with DB
    remaining = books.select { |b| wrong_publishers.include?(b['publisher'].to_s.strip) }
    puts "Total Harivu books: #{books.length}"
    puts "Remaining to scrape: #{remaining.length}"

    error_count = 0
    skip_count = 0
    consecutive_errors = 0

    remaining.each_with_index do |book, idx|
      url = book['book_link']
      unless url && url.start_with?('http')
        skip_count += 1
        next
      end

      print "\r  [#{idx + 1}/#{remaining.length}] #{book['name'][0..45]}... "

      begin
        resp = fetch_harivu(url, timeout: 15)
        code = resp.code.to_i

        if code == 429
          puts "429 (backoff 5s)"
          consecutive_errors += 1
          sleep 5 * consecutive_errors
          redo
        end

        unless code == 200
          puts "HTTP #{code}"
          error_count += 1
          consecutive_errors += 1
          sleep 1
          next
        end

        consecutive_errors = 0
        correct = extract_publisher_from_page(resp.body)

        unless correct
          puts "NO PUBLISHER"
          error_count += 1
          sleep 0.3
          next
        end

        old = book['publisher']
        book['publisher'] = correct
        total_fixed_in_run += 1
        puts "✓ #{correct}"

        Book.where(source_identifier: book['source_identifier']).update_all(publisher: correct)

      rescue => e
        puts "ERR: #{e.message[0..50]}"
        error_count += 1
        consecutive_errors += 1
      end

      sleep 0.5
    end

    # Save JSON
    File.write(file_path, JSON.pretty_generate(books))
    puts "\n\n=== Results ==="
    puts "Fixed in this run: #{total_fixed_in_run}"
    puts "Errors: #{error_count}"
    puts "Skipped: #{skip_count}"

    still_wrong = books.select { |b| wrong_publishers.include?(b['publisher'].to_s.strip) }
    puts "Still wrong in JSON: #{still_wrong.length}"
    db_wrong = Book.where(publisher: ['Harivu Books', 'Harivu Books Publication', 'Harivu', 'Regular price']).count
    puts "Still wrong in DB: #{db_wrong}"
    db_kn = Book.where('publisher LIKE ?', '%ಹರಿವು%').count
    puts "DB with Kannada 'ಹರಿವು' (actual correct publisher): #{db_kn}"
  end
end
