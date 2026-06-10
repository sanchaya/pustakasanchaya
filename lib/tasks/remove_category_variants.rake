namespace :categories do
  desc "Remove all variants of category text"
  task :remove_variants => :environment do
    texts_to_remove = [
      "All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು, 20%, ",
      "20%, All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು, ",
      "30%, All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು, ",
      "40%, All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು,",
      "50%, All Books / ಎಲ್ಲಾ ಪುಸ್ತಕಗಳು, "
    ]
    
    total_updated = 0
    
    texts_to_remove.each do |text|
      # Find all books that have this text in their categories
      candidates = Book.where("categories LIKE ?", "%#{Book.connection.quote_string(text)}%")
      puts "Found #{candidates.count} books with: #{text.inspect}"
      
      count = 0
      candidates.find_each do |book|
        old_categories = book.categories
        # Remove the specific text from the categories string
        new_categories = old_categories.gsub(text, '')
        
        if new_categories != old_categories
          book.update_column(:categories, new_categories)
          puts "  Updated book #{book.id}: #{book.name}"
          count += 1
          total_updated += 1
        end
      end
      
      puts "  Updated #{count} books for this variant\n"
    end
    
    Book.bump_search_cache
    puts "Successfully updated #{total_updated} books total"
  end
end
