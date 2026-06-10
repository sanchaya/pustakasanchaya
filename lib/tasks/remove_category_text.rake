namespace :categories do
  desc "Remove specific text from category field"
  task :remove_text => :environment do
    text_to_remove = "All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು, 20%, "
    
    # Find all books that have this text in their categories
    candidates = Book.where("categories LIKE ?", "%#{text_to_remove}%")
    puts "Found #{candidates.count} books with this text in categories"
    
    count = 0
    candidates.find_each do |book|
      old_categories = book.categories
      # Remove the specific text from the categories string
      new_categories = old_categories.gsub(text_to_remove, '')
      
      if new_categories != old_categories
        book.update_column(:categories, new_categories)
        puts "Updated book #{book.id}: #{book.name}"
        count += 1
      end
    end
    
    Book.bump_search_cache
    puts "Successfully updated #{count} books"
  end
end
