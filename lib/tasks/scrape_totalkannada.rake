namespace :scrape do
  desc "Scrape author, publisher, year from totalkannada.com product pages (batched)"
  task totalkannada: :environment do
    require 'httparty'
    require 'nokogiri'

    tk_lib = 'ಟೋಟಲ್ ಕನ್ನಡ'
    delay = (ENV['DELAY'] || 0.3).to_f
    batch = (ENV['BATCH'] || 500).to_i
    offset = (ENV['OFFSET'] || 0).to_i

    books = Book.where(library: tk_lib)
                .where('author IS NULL OR author = ? OR publisher IS NULL OR publisher = ? OR year IS NULL OR year = ? OR year = ?',
                       '', '', '', '0')
                .order(:id)
                .offset(offset)
                .limit(batch)

    total = books.count
    processed = 0
    updated = 0
    failed = 0

    puts "Starting batch (offset=#{offset}, limit=#{batch})"

    books.each do |book|
      processed += 1
      uuid = book.source_identifier.sub('totalkannada_', '')
      url = "https://www.totalkannada.com/products/#{uuid}.html"

      begin
        response = HTTParty.get(url, follow_redirects: true, timeout: 10)
        unless response.success?
          failed += 1
          sleep(delay)
          next
        end

        doc = Nokogiri::HTML(response.body)
        author = nil
        publisher = nil
        year = nil

        doc.css('p.text-gray-500').each do |label|
          text = label.text.strip
          next if text.empty?
          value = label.next_element
          next unless value
          val_text = value.text.strip.gsub(/\u00A0/, ' ').strip

          case text
          when /Author/i then author = val_text unless val_text.empty?
          when /Publisher/i then publisher = val_text unless val_text.empty?
          when /Publication Year/i then year = val_text unless val_text.empty?
          end
        end

        updates = {}
        updates[:author] = author if author.present? && book.author.blank?
        updates[:publisher] = publisher if publisher.present? && book.publisher.blank?
        updates[:year] = year if year.present? && (book.year.blank? || book.year == '0')

        unless updates.empty?
          Book.where(id: book.id).update_all(updates)
          updated += 1
        end

      rescue => e
        failed += 1
      end

      sleep(delay)
    end

    puts "Batch done: #{processed} processed, #{updated} updated, #{failed} failed"
  end
end
