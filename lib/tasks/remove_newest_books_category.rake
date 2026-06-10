namespace :categories do
  desc "Remove 'Newest Books / ಈಚಿನ ಪ್ರಕಟಣೆಗಳು' category from all books"
  task :remove_newest_books => :environment do
    category_to_remove = "Newest Books / ಈಚಿನ ಪ್ರಕಟಣೆಗಳು"
    
    # Find all books that have this category
    candidates = Book.where("categories LIKE ?", "%#{ActiveRecord::Base.connection.quote_string(category_to_remove)}%")
    puts "Found #{candidates.count} books with category: #{category_to_remove}\n\n"
    
    count = 0
    candidates.find_each do |book|
      old_categories = book.categories
      
      # Split by comma and clean up
      cats = old_categories.split(',').map(&:strip)
      # Remove the specific category
      new_cats = cats.reject { |c| c == category_to_remove }
      
      if new_cats.length != cats.length
        # Reconstruct the categories string
        new_categories = new_cats.join(', ')
        book.update_column(:categories, new_categories)
        puts "Updated book #{book.id}: #{book.name}"
        count += 1
      end
    end
    
    Book.bump_search_cache
    puts "\n✓ Successfully removed category from #{count} books"
  end
end
