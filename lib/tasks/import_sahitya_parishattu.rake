namespace :import do
  desc "Import books from Kannada Sahitya Parishattu Google Sheets CSV"
  task sahitya_parishattu: :environment do
    require 'csv'
    require 'net/http'
    require 'uri'

    CSV_URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTfuY7Dbh__BarDotBZxZl1obpOLFVzKDFYu-bnvw8Mpzte0u7SZGK2YmdOfPGWWVbQXzxFJE_nDq5-/pub?output=csv"
    SOURCE_NAME = "ಕನ್ನಡ ಸಾಹಿತ್ಯ ಪರಿಷತ್ತು"

    puts "📥 Fetching CSV from Google Sheets..."
    
    uri = URI(CSV_URL)
    response = Net::HTTP.get(uri)
    
    puts "📊 Parsing CSV data..."
    csv = CSV.parse(response, headers: true)
    
    puts "📚 Found #{csv.length} books to import"
    
    imported = 0
    skipped = 0
    errors = 0
    
    csv.each do |row|
      begin
        title = row['Title']&.strip
        author = row['Author']&.strip
        category = row['Category']&.strip
        publisher = row['Publisher']&.strip
        
        next if title.blank? || author.blank?
        
        # Create a unique identifier from title + author
        source_id = "KSP-#{Digest::MD5.hexdigest("#{title}-#{author}")[0,8]}"
        
        book = Book.find_or_initialize_by(source_identifier: source_id)
        
        book.update!(
          name: title,
          name_english: title,  # Same for now
          author: author,
          publisher: publisher,
          categories: category,
          library: SOURCE_NAME,
          source: SOURCE_NAME,
          language: 'kan',
          year: nil,
          isbn: nil,
          thumbnail: nil,
          updated_at: Time.now
        )
        
        imported += 1
        
      rescue StandardError => e
        puts "❌ Error importing '#{row['Title']}': #{e.message}"
        errors += 1
      end
    end
    
    puts "\n✅ Import Complete!"
    puts "   Imported: #{imported}"
    puts "   Skipped:  #{skipped}"
    puts "   Errors:   #{errors}"
    puts "   Source:   #{SOURCE_NAME}"
  end
end