require 'httparty'
require 'json'

namespace :ia do
  desc "Update all IA books with published year from archive.org API"
  task update_years: :environment do
    puts "Starting IA year update..."
    
    # Load all IA books
    jai_gyan = JSON.parse(File.read('db/jai_gyan_books.json')) rescue []
    servants = JSON.parse(File.read('db/servants_of_knowledge_books.json')) rescue []
    
    all_ia_books = jai_gyan + servants
    total = all_ia_books.length
    updated = 0
    skipped = 0
    errors = 0
    
    puts "Processing #{total} IA books..."
    
    all_ia_books.each_with_index do |book, idx|
      print "\r[#{idx + 1}/#{total}] Updated: #{updated}, Skipped: #{skipped}, Errors: #{errors}"
      
      # Skip if year already present and not "0" or empty
      if book['year'].present? && book['year'] != "0" && book['year'] != ""
        skipped += 1
        next
      end
      
      # Extract identifier from archive_url
      identifier = book['source_identifier'] || extract_identifier(book['archive_url'])
      next unless identifier.present?
      
      # Fetch from IA API
      begin
        response = HTTParty.get(
          "https://archive.org/advancedsearch.php",
          query: {
            q: "identifier:\"#{identifier}\"",
            output: 'json',
            rows: 1
          },
          timeout: 10
        )
        
        if response.is_a?(Hash) && response['response'] && response['response']['docs']
          docs = response['response']['docs']
          if docs.length > 0
            doc = docs.first
            
            # Extract year from various fields
            published_year = nil
            
            # Try "date" field first (YYYY format)
            if doc['date'].present?
              published_year = doc['date'][0..3].to_i if doc['date'].to_s =~ /^\d{4}/
            end
            
            # Try "publishdate" field
            if published_year.nil? && doc['publishdate'].present?
              published_year = doc['publishdate'].to_s[0..3].to_i if doc['publishdate'].to_s =~ /^\d{4}/
            end
            
            # Try "year" field (array)
            if published_year.nil? && doc['year'].present?
              years = Array(doc['year'])
              published_year = years.first.to_i if years.first.to_s =~ /^\d{4}/
            end
            
            # Try "year_published" field
            if published_year.nil? && doc['year_published'].present?
              published_year = doc['year_published'].to_s.to_i if doc['year_published'].to_s =~ /^\d{4}/
            end
            
            # Update the book if we found a year
            if published_year.present? && published_year > 0 && published_year <= Date.today.year
              book['year'] = published_year.to_s
              updated += 1
            else
              skipped += 1
            end
          else
            skipped += 1
          end
        else
          skipped += 1
        end
      rescue StandardError => e
        errors += 1
        # Continue with next book
      end
      
      # Rate limiting: 2 requests per second
      sleep 0.5 if (idx + 1) % 2 == 0
    end
    
    puts "\n\nUpdating database files..."
    
    # Split back into original sources
    updated_jai_gyan = all_ia_books[0...jai_gyan.length]
    updated_servants = all_ia_books[jai_gyan.length..-1]
    
    File.write('db/jai_gyan_books.json', JSON.generate(updated_jai_gyan))
    File.write('db/servants_of_knowledge_books.json', JSON.generate(updated_servants))
    
    puts "✓ Updated: #{updated} books"
    puts "✓ Skipped: #{skipped} books (already have year)"
    puts "✗ Errors: #{errors} books"
    puts "✓ Files saved: db/jai_gyan_books.json, db/servants_of_knowledge_books.json"
  end
  
  def extract_identifier(url)
    return nil unless url.present?
    # Extract from URLs like https://archive.org/details/IDENTIFIER
    match = url.match(%r{archive\.org/details/([^/?]+)})
    match[1] if match
  end
end
