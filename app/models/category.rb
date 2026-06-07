require 'set'

class Category
  # Get all unique categories from books
  def self.all_categories
    all_books = load_all_books
    categories = Set.new
    
    all_books.each do |book|
      book_categories = book['category'].to_s.strip
      next if book_categories.blank?
      
      # Handle comma-separated categories
      book_categories.split(',').each do |cat|
        clean_cat = cat.strip
        categories << clean_cat if clean_cat.present?
      end
    end
    
    categories.sort
  end

  # Get all unique categories with book counts
  def self.all_with_counts
    all_books = load_all_books
    category_counts = {}
    
    all_books.each do |book|
      book_categories = book['category'].to_s.strip
      next if book_categories.blank?
      
      book_categories.split(',').each do |cat|
        clean_cat = cat.strip
        next if clean_cat.blank?
        
        category_counts[clean_cat] ||= 0
        category_counts[clean_cat] += 1
      end
    end
    
    category_counts.sort_by { |_k, v| -v }
  end

  # Find similar categories
  def self.find_similar(category_name, threshold = 0.85)
    return [] if category_name.blank?
    
    all = all_categories
    category_name_lower = category_name.strip.downcase
    
    similar = all.select do |other|
      other_lower = other.downcase
      
      # Skip exact match
      next false if category_name_lower == other_lower
      
      # Levenshtein distance
      similarity = levenshtein_similarity(category_name_lower, other_lower)
      
      # Fuzzy matching
      fuzzy = other_lower.include?(category_name_lower) || category_name_lower.include?(other_lower)
      
      similarity >= threshold || fuzzy
    end
    
    similar.sort_by { |other| -levenshtein_similarity(category_name_lower, other.downcase) }
  end

  # Merge two categories (replace old_category with new_category)
  def self.merge(old_category, new_category, editor_email)
    return { success: false, error: 'Categories cannot be blank' } if old_category.blank? || new_category.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      book_categories = book['category'].to_s.strip
      next if book_categories.blank?
      
      # Check if book has the old category
      if book_categories.downcase == old_category.downcase
        old_value = book_categories
        new_value = new_category
        
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'category',
          old_value,
          new_value,
          editor_email,
          "Merged category: '#{old_category}' → '#{new_category}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_category: old_value,
          new_category: new_value
        }
      end
    end
    
    {
      success: true,
      merged_from: old_category,
      merged_to: new_category,
      affected_count: affected_books.length,
      affected_books: affected_books
    }
  end

  # Rename a category
  def self.rename(old_name, new_name, editor_email)
    return { success: false, error: 'Category names cannot be blank' } if old_name.blank? || new_name.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      book_categories = book['category'].to_s.strip
      next if book_categories.blank?
      
      if book_categories.downcase == old_name.downcase
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'category',
          book_categories,
          new_name,
          editor_email,
          "Renamed category: '#{old_name}' → '#{new_name}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_name: book_categories,
          new_name: new_name
        }
      end
    end
    
    {
      success: true,
      renamed_from: old_name,
      renamed_to: new_name,
      affected_count: affected_books.length,
      affected_books: affected_books
    }
  end

  private

  def self.levenshtein_similarity(str1, str2)
    distance = levenshtein_distance(str1, str2)
    max_length = [str1.length, str2.length].max
    return 1.0 if max_length == 0
    1.0 - (distance.to_f / max_length)
  end

  def self.levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }
    
    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }
    
    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].min
      end
    end
    
    matrix[str1.length][str2.length]
  end

  def self.load_all_books
    @all_books_cache ||= (
      Book.load_jai_gyan_cache +
      Book.load_servants_cache +
      Book.load_ankita_cache +
      Book.load_ruthumana_cache +
      Book.load_harivu_cache +
      Book.load_kbh_cache +
      Book.load_nkp_cache +
      Book.load_google_books_cache
    )
  end
end
