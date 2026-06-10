namespace :categories do
  desc "Automatically merge similar categories"
  task :merge_similar => :environment do
    # Define merges: [source_category, target_category]
    merges = [
      # Children's categories
      ["Children Book, Story Book", "Children Books"],
      ["Children Books, ಮಕ್ಕಳ ಪುಸ್ತಕಗಳು", "Children Books"],
      ["ಮಕ್ಕಳ ಸಾಹಿತ್ಯ", "Children Books"],
      
      # Biography variants
      ["Biography", "Biographies Books, ಜೀವನ ಚರಿತ್ರೆ"],
      ["Mini Biography Series, ವಿಶ್ವಮಾನ್ಯರು ಮಾಲಿಕೆ", "Biographies Books, ಜೀವನ ಚರಿತ್ರೆ"],
      ["Adhunika-Mahapurusharu", "Biographies Books, ಜೀವನ ಚರಿತ್ರೆ"],
      
      # Story variants
      ["Short Stories, ಕಥಾ ಸಂಕಲನ", "Stories, ಕತೆಗಳು"],
      ["ಸಣ್ಣ ಕಥೆ", "Stories, ಕತೆಗಳು"],
      ["Story Book", "Stories, ಕತೆಗಳು"],
      
      # History variants
      ["History", "History, ಇತಿಹಾಸ"],
      ["ಇತಿಹಾಸ ವಿಜ್ಞಾನ", "History, ಇತಿಹಾಸ"],
      
      # General variants
      ["ಸಾಮಾನ್ಯ", "General Books, ಸಾಮಾನ್ಯ ಇತರೆ ಪುಸ್ತಕಗಳು"],
      ["Books", "General Books, ಸಾಮಾನ್ಯ ಇತರೆ ಪುಸ್ತಕಗಳು"],
      ["Others", "General Books, ಸಾಮಾನ್ಯ ಇತರೆ ಪುಸ್ತಕಗಳು"],
      
      # Drama/Play variants
      ["Plays, Drama, ನಾಟಕ", "Drama"],
      
      # Religious variants
      ["Mythology, Religious, Epic, ಪುರಾಣ, ಧಾರ್ಮಿಕ", "Religious"],
      ["Devotional", "Religious"],
      
      # Health/Medical variants
      ["Health, Medical Books,ಆರೋಗ್ಯ, ವೈದ್ಯಕೀಯ, ಮನೋವೈದ್ಯಕೀಯ", "Medical"],
      
      # Science variants
      ["Science, ವಿಜ್ಞಾನ", "Science"],
      
      # Poetry variants
      ["Poetry, ಕಾವ್ಯ", "Poetry"],
      
      # Autobiography variants
      ["Autobiography, ಆತ್ಮಕಥನ", "Autobiography"],
      
      # Self Improvement variants
      ["Self Improvement,Personality Develop, ವ್ಯಕ್ತಿ ವಿಕಸನ ಮಾಲೆ", "Self Improvement"],
      
      # Articles/Essays variants
      ["Articles, Essays, ಲೇಖನಗಳು, ಪ್ರಬಂಧಗಳು, ಅಂಕಣ ಬರಹಗಳು", "Articles"],
    ]
    
    total_merged = 0
    failed_merges = []
    admin_email = "admin@example.com" # Default admin email for logging
    
    merges.each do |source, target|
      puts "\nAttempting to merge: '#{source}' → '#{target}'"
      
      # Check if source category exists
      source_count = Book.where("categories LIKE ?", "%#{ActiveRecord::Base.connection.quote_string(source)}%").count
      target_count = Book.where("categories LIKE ?", "%#{ActiveRecord::Base.connection.quote_string(target)}%").count
      
      if source_count == 0
        puts "  ⚠️  Source category not found (0 books)"
        next
      end
      
      puts "  Found #{source_count} books with source category"
      puts "  Target category has #{target_count} books"
      
      # Use Category.merge to merge the categories
      result = Category.merge(source, target, admin_email)
      
      if result[:success]
        puts "  ✓ Merged #{result[:affected_count]} books"
        total_merged += result[:affected_count]
      else
        puts "  ✗ Error: #{result[:error]}"
        failed_merges << [source, target, result[:error]]
      end
    end
    
    # Update search cache
    Book.bump_search_cache
    
    puts "\n" + "="*60
    puts "MERGE SUMMARY"
    puts "="*60
    puts "Total books merged: #{total_merged}"
    puts "Failed merges: #{failed_merges.length}"
    
    if failed_merges.any?
      puts "\nFailed merges:"
      failed_merges.each do |source, target, error|
        puts "  - #{source} → #{target}: #{error}"
      end
    end
    
    puts "\nDone!"
  end
end
