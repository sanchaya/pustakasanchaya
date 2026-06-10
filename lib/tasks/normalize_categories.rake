namespace :categories do
  desc "Normalize and analyze all categories in books"
  task :analyze => :environment do
    puts "Analyzing all categories in books...\n"
    
    all_categories = {}
    
    Book.find_each do |book|
      next if book.categories.blank?
      
      # Parse categories using Book's method
      cats = Book.parse_categories_string(book.categories)
      
      cats.each do |cat|
        cat_clean = cat.strip
        next if cat_clean.blank?
        
        all_categories[cat_clean] ||= 0
        all_categories[cat_clean] += 1
      end
    end
    
    # Sort by frequency
    sorted = all_categories.sort_by { |_k, v| -v }
    
    puts "Total unique categories: #{sorted.length}\n\n"
    puts "Categories by frequency:"
    sorted.each do |cat, count|
      puts "  #{count.to_s.rjust(5)} books: #{cat}"
    end
    
    # Save to file for analysis
    File.open('/tmp/categories_analysis.txt', 'w') do |f|
      f.puts "Total unique categories: #{sorted.length}\n\n"
      f.puts "Categories by frequency:\n"
      sorted.each do |cat, count|
        f.puts "#{count}\t#{cat}"
      end
    end
    
    puts "\n\nAnalysis saved to /tmp/categories_analysis.txt"
  end

  desc "Find similar categories using Levenshtein distance"
  task :find_similar => :environment do
    puts "Finding similar categories...\n"
    
    all_categories = {}
    
    Book.find_each do |book|
      next if book.categories.blank?
      cats = Book.parse_categories_string(book.categories)
      cats.each do |cat|
        cat_clean = cat.strip
        next if cat_clean.blank?
        all_categories[cat_clean] ||= 0
        all_categories[cat_clean] += 1
      end
    end
    
    categories_list = all_categories.keys.sort
    
    # Find pairs with high similarity
    similar_pairs = []
    categories_list.each_with_index do |cat1, i|
      (i + 1...categories_list.length).each do |j|
        cat2 = categories_list[j]
        similarity = levenshtein_similarity(cat1.downcase, cat2.downcase)
        if similarity > 0.75
          similar_pairs << [cat1, cat2, similarity, all_categories[cat1], all_categories[cat2]]
        end
      end
    end
    
    # Sort by similarity
    similar_pairs.sort_by! { |_, _, sim, _, _| -sim }
    
    puts "Found #{similar_pairs.length} potentially similar category pairs:\n\n"
    similar_pairs.each do |cat1, cat2, sim, count1, count2|
      puts "Similarity: #{(sim * 100).round(1)}%"
      puts "  #{count1} books: #{cat1}"
      puts "  #{count2} books: #{cat2}"
      puts
    end
    
    # Save to file
    File.open('/tmp/similar_categories.txt', 'w') do |f|
      f.puts "Found #{similar_pairs.length} potentially similar category pairs:\n\n"
      similar_pairs.each do |cat1, cat2, sim, count1, count2|
        f.puts "#{(sim * 100).round(1)}%\t#{cat1}\t(#{count1})\t<->\t#{cat2}\t(#{count2})"
      end
    end
    
    puts "\nAnalysis saved to /tmp/similar_categories.txt"
  end

  private

  def levenshtein_similarity(str1, str2)
    distance = levenshtein_distance(str1, str2)
    max_length = [str1.length, str2.length].max
    return 1.0 if max_length == 0
    1.0 - (distance.to_f / max_length)
  end

  def levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }
    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }
    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        matrix[i][j] = [matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost].min
      end
    end
    matrix[str1.length][str2.length]
  end
end
