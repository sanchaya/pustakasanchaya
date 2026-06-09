namespace :import do
  desc "Import books and categories from Samooha Sanchaya database"
  task samooha: :environment do
    require 'mysql2'

    samooha_client = Mysql2::Client.new(
      host: 'localhost',
      username: 'samooha_sanchaya',
      password: 'cHDSLwrwnk3g',
      database: 'samooha_sanchaya',
      encoding: 'utf8'
    )

    puts "=== Starting Samooha Data Import ==="
    puts "Time: #{Time.now}"

    # Step 1: Import categories
    import_categories(samooha_client)

    # Step 2: Import books and their categories
    import_books(samooha_client)

    puts "=== Import Complete ==="
  end

  def import_categories(client)
    puts "\n--- Importing Categories ---"
    
    categories = client.query("SELECT id, kn FROM categories WHERE kn IS NOT NULL AND kn != ''")
    imported = 0
    skipped = 0

    categories.each do |cat|
      kn_name = cat['kn'].strip
      next if kn_name.blank?

      # Check if category already exists in local books
      exists = Book.where("categories LIKE ?", "%#{Book.escape_like(kn_name)}%").exists?
      
      if exists
        skipped += 1
      else
        # For now, we just note it. Categories in local DB are inline in books.categories
        # We'll add them when importing books
        imported += 1
      end
    end

    puts "Categories processed: #{imported + skipped}"
    puts "  Already present in local books: #{skipped}"
    puts "  New categories (will be added via books): #{imported}"
  end

  def import_books(client)
    puts "\n--- Importing Books ---"

    # Get all Samooha books with their categories
    query = <<-SQL
      SELECT 
        kb.id,
        kb.name,
        kb.author,
        kb.publisher,
        kb.library,
        kb.book_link,
        kb.barcode,
        kb.year,
        kb.archive_url,
        kb.wikimedia_url,
        kb.wikisource_url,
        kb.rights,
        kb.reviewed,
        kb.created_at,
        GROUP_CONCAT(c.kn SEPARATOR '||') as category_names
      FROM kannada_books kb
      LEFT JOIN kannada_book_categories kbc ON kb.id = kbc.kannada_book_id
      LEFT JOIN categories c ON kbc.category_id = c.id
      WHERE kb.name IS NOT NULL AND kb.name != ''
      GROUP BY kb.id
    SQL

    samooha_books = client.query(query)
    total = samooha_books.count
    imported = 0
    skipped = 0
    errors = 0

    puts "Found #{total} books in Samooha"

    samooha_books.each_with_index do |book, index|
      print "\rProcessing #{index + 1}/#{total}..."

      begin
        # Generate source_identifier from archive_url or book_link
        source_id = generate_source_identifier(book)
        
        # Check if book already exists
        existing = Book.find_by(source_identifier: source_id)
        
        if existing
          # Update categories if book exists
          update_book_categories(existing, book['category_names'])
          skipped += 1
        else
          # Create new book
          create_book_from_samooha(book, source_id)
          imported += 1
        end
      rescue => e
        errors += 1
        puts "\nError importing book #{book['id']}: #{e.message}"
      end
    end

    puts "\nBooks processed: #{total}"
    puts "  Imported: #{imported}"
    puts "  Skipped (already exist): #{skipped}"
    puts "  Errors: #{errors}"
  end

  def generate_source_identifier(book)
    # Use archive.org identifier as source_identifier
    if book['archive_url'].present?
      # Extract identifier from archive.org URL
      if match = book['archive_url'].match(/archive\.org\/details\/([^\/\?]+)/)
        return "samooha_#{match[1]}"
      end
    end
    
    # Fallback to book_link
    if book['book_link'].present?
      if match = book['book_link'].match(/[^\/]+$/)
        return "samooha_#{match[0]}"
      end
    end

    # Last resort: name + author hash
    "samooha_#{Digest::MD5.hexdigest("#{book['name']}#{book['author']}")[0,12]}"
  end

  def create_book_from_samooha(samooha_book, source_id)
    categories = parse_categories(samooha_book['category_names'])
    
    book_attrs = {
      source_identifier: source_id,
      name: samooha_book['name'].to_s.strip,
      author: samooha_book['author']&.to_s&.strip,
      publisher: samooha_book['publisher']&.to_s&.strip,
      library: samooha_book['library']&.to_s&.strip,
      year: samooha_book['year'].to_s.strip,
      book_link: samooha_book['book_link']&.to_s&.strip,
      archive_url: samooha_book['archive_url']&.to_s&.strip,
      categories: Book.serialize_categories(categories),
      source: 'Samooha',
      language: 'kn',
      created_at: samooha_book['created_at'] || Time.now,
      updated_at: samooha_book['created_at'] || Time.now
    }

    # Handle archive_url normalization
    book_attrs[:archive_url] = book_attrs[:archive_url]&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
    book_attrs[:book_link] = book_attrs[:book_link]&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')

    Book.create!(book_attrs)
  end

  def update_book_categories(book, category_names)
    return if category_names.blank?
    
    samooha_categories = parse_categories(category_names)
    return if samooha_categories.empty?

    existing_categories = Book.parse_categories_string(book.categories)
    combined = (existing_categories + samooha_categories).uniq
    
    if combined != existing_categories
      book.update_column(:categories, Book.serialize_categories(combined))
      puts "  Updated categories for #{book.source_identifier}"
    end
  end

  def parse_categories(category_string)
    return [] if category_string.blank?
    category_string.split('||').map(&:strip).reject(&:blank?)
  end
end