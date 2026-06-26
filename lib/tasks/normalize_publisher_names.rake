namespace :publishers do
  desc "Split combined Kannada/English publisher names into kannada and latin columns"
  task :split_kannada_english => :environment do
    # Kannada unicode range: \u0C80-\u0CFF (Kannada script)
    # Latin ASCII range: basically characters that are ASCII letters

    books = Book.where("publisher LIKE '%,%'")
                .where(publisher_kannada: nil)
                .where(publisher_latin: nil)

    total = books.count
    puts "Found #{total} books with comma-separated publisher names to process"
    updated = 0
    skipped = 0

    books.find_each do |book|
      publisher = book.publisher.to_s.strip
      parts = publisher.split(',').map(&:strip)
      
      next if parts.length < 2

      kannada_part = parts.select { |p| p.match?(/[\u0C80-\u0CFF]/) }
      latin_part = parts.select { |p| p.match?(/\A[a-zA-Z0-9\s\.\&\/\(\)\-]+\z/) }

      kannada = kannada_part.first
      latin = latin_part.first

      if kannada.present? && latin.present? && kannada != latin
        book.update_columns(publisher_kannada: kannada, publisher_latin: latin)
        updated += 1
        puts "  ✓ #{publisher} → kannada: #{kannada}, latin: #{latin}"
      else
        skipped += 1
      end
    end

    puts "\nDone. Updated: #{updated}, Skipped: #{skipped}"
  end
end
