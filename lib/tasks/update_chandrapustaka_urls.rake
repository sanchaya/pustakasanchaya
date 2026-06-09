namespace :stores do
  desc "Update store_url for books from 'ಟೋಟಲ್ ಕನ್ನಡ' store"
  task update_chandrapustaka_urls: :environment do
    store_name = "ಟೋಟಲ್ ಕನ್ನಡ"
    
    # Find the store ID for 'ಟೋಟಲ್ ಕನ್ನಡ'
    store = Store.find_by(name: store_name)
    
    unless store
      puts "Store '#{store_name}' not found. Please create it first."
      exit
    end
    
    puts "Found store '#{store.name}' with ID: #{store.id}"
    
    # Find book_stores entries for this store
    book_stores = BookStore.where(store_id: store.id)
    
    if book_stores.empty?
      puts "No book_stores entries found for store '#{store.name}'."
      exit
    end
    
    puts "Found #{book_stores.count} book_stores entries for '#{store.name}'. Processing..."
    
    updated_count = 0
    
    # Iterate through book_stores and update store_url using book.book_link
    book_stores.each do |bs|
      book = Book.find_by(id: bs.book_id)
      
      if book && book.book_link.present?
        if bs.store_url != book.book_link
          bs.update(store_url: book.book_link)
          updated_count += 1
        end
      else
        puts "Warning: Book ID #{bs.book_id} not found or missing book_link for store '#{store.name}'."
      end
    end
    
    puts "\nUpdate complete!"
    puts "  Store: '#{store.name}'"
    puts "  Updated #{updated_count} store_url(s)."
  end
end