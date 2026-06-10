namespace :books do
  desc "Remove all books by a specific author"
  task :remove_by_author => :environment do
    author_name = "ಕರ್ನಾಟಕ ವಿಧಾನಮಂಡಲ"
    
    # Find all books by this author
    books = Book.where(author: author_name)
    puts "Found #{books.count} books with author: #{author_name}\n\n"
    
    if books.count == 0
      puts "No books found with this author."
      return
    end
    
    # Display books before deletion
    puts "Books to be deleted:"
    books.each do |book|
      puts "  - #{book.id}: #{book.name}"
    end
    
    puts "\n" + "="*60
    puts "Deleting #{books.count} books..."
    puts "="*60 + "\n"
    
    # Delete the books
    count = books.count
    books.destroy_all
    
    # Update search cache
    Book.bump_search_cache
    
    puts "✓ Successfully deleted #{count} books"
  end
end
