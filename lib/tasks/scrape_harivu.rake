namespace :scrape do
  desc "Scrape author, publisher from harivubooks.com product pages (37 placeholder-author books)"
  task harivu: :environment do
    require 'httparty'
    require 'nokogiri'

    lib_name = 'ಹರಿವು ಬುಕ್ಸ್'
    delay = (ENV['DELAY'] || 0.5).to_f

    books = Book.joins(:book_stores)
                .where(books: { library: lib_name, author: ['Harivu Books', nil, ''] })
                .distinct

    total = books.count
    puts "Found #{total} books to process in #{lib_name}"
    processed = 0
    updated = 0
    failed = 0

    books.find_each do |book|
      processed += 1
      store_link = book.book_stores.first&.store_url
      unless store_link
        puts "  [SKIP] Book #{book.id} has no store URL"
        failed += 1
        next
      end

      begin
        response = HTTParty.get(store_link, follow_redirects: true, timeout: 10)
        unless response.success?
          puts "  [FAIL] Book #{book.id} HTTP #{response.code} for #{store_link}"
          failed += 1
          sleep(delay)
          next
        end

        body = response.body
        author = body[/"vendor":"([^"]+)"/, 1]
        if author.blank?
          puts "  [FAIL] Book #{book.id} no vendor/author found"
          failed += 1
          sleep(delay)
          next
        end

        updates = { author: author }
        updates[:publisher] = $1 if body[/"vendor":"[^"]+","type":"([^"]+)"/, 1].present? rescue nil

        Book.where(id: book.id).update_all(updates)
        updated += 1
        puts "  [OK] Book #{book.id}: author='#{author}' #{updates[:publisher] ? "publisher='#{updates[:publisher]}'" : ''}"

      rescue => e
        puts "  [ERR] Book #{book.id}: #{e.message}"
        failed += 1
      end

      sleep(delay)
    end

    puts "Done: #{processed} processed, #{updated} updated, #{failed} failed"
  end
end
