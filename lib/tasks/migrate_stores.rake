namespace :stores do
  desc "Migrate existing library data to stores and book_stores"
  task migrate_libraries: :environment do
    puts "Starting library to store migration..."
    
    libraries = Book.distinct.pluck(:library).reject(&:blank?).sort
    
    puts "Found #{libraries.size} unique libraries:"
    libraries.each { |lib| puts "  - #{lib}" }
    
    # Create stores for each library
    stores_map = {}
    libraries.each_with_index do |library_name, index|
      store = Store.find_or_initialize_by(name: library_name)
      store.position = index
      store.active = true
      if store.save
        stores_map[library_name] = store.id
        puts "Created store: #{library_name} (ID: #{store.id})"
      else
        puts "Error creating store #{library_name}: #{store.errors.full_messages.join(', ')}"
      end
    end
    
    puts "\nMigrated #{stores_map.size} stores"
    
    # Create book_stores records
    total_books = Book.count
    processed = 0
    created = 0
    
    Book.find_each do |book|
      next if book.library.blank?
      
      store_id = stores_map[book.library]
      next unless store_id
      
      BookStore.find_or_create_by(book_id: book.id, store_id: store_id) do |bs|
        bs.store_url = book.book_link
        bs.availability = 'available'
      end
      
      created += 1
      processed += 1
      
      if processed % 1000 == 0
        puts "Processed #{processed}/#{total_books} books, created #{created} book_stores"
      end
    end
    
    puts "\nMigration complete!"
    puts "  Processed books: #{processed}"
    puts "  Created book_stores: #{created}"
    puts "  Total stores: #{Store.count}"
    puts "  Total book_stores: #{BookStore.count}"
  end
end