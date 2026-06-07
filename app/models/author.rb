require 'set'

class Author
  # Extract and deduplicate all authors from books
  def self.all_authors
    all_books = load_all_books
    authors = Set.new
    
    all_books.each do |book|
      author = book['author'].to_s.strip
      next if author.blank?
      
      # Handle comma-separated authors
      author.split(',').each do |a|
        clean_author = a.strip
        authors << clean_author if clean_author.present?
      end
    end
    
    authors.sort
  end

  # Get all unique authors with book counts
  def self.all_with_counts
    all_books = load_all_books
    author_counts = {}
    
    all_books.each do |book|
      author = book['author'].to_s.strip
      next if author.blank?
      
      author.split(',').each do |a|
        clean_author = a.strip
        next if clean_author.blank?
        
        author_counts[clean_author] ||= 0
        author_counts[clean_author] += 1
      end
    end
    
    author_counts.sort_by { |_k, v| -v }
  end

  # Find similar authors using multiple algorithms
  def self.find_similar(author_name, threshold = 0.85)
    return [] if author_name.blank?
    
    all = all_authors
    author_name_lower = author_name.strip.downcase
    
    similar = all.select do |other|
      other_lower = other.downcase
      
      # Skip exact match
      next false if author_name_lower == other_lower
      
      # Levenshtein distance
      similarity = levenshtein_similarity(author_name_lower, other_lower)
      
      # Fuzzy matching - check if one contains the other
      fuzzy = other_lower.include?(author_name_lower) || author_name_lower.include?(other_lower)
      
      similarity >= threshold || fuzzy
    end
    
    similar.sort_by { |other| -levenshtein_similarity(author_name_lower, other.downcase) }
  end

  # Merge two authors (replace old_author with new_author in all books)
  def self.merge(old_author, new_author, editor_email)
    return { success: false, error: 'Authors cannot be blank' } if old_author.blank? || new_author.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      author = book['author'].to_s.strip
      next if author.blank?
      
      # Check if book has the old author
      if author.downcase == old_author.downcase
        old_value = author
        new_value = new_author
        
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'author',
          old_value,
          new_value,
          editor_email,
          "Merged author: '#{old_author}' → '#{new_author}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_author: old_value,
          new_author: new_value
        }
      end
    end
    
    {
      success: true,
      merged_from: old_author,
      merged_to: new_author,
      affected_count: affected_books.length,
      affected_books: affected_books
    }
  end

  # Rename an author
  def self.rename(old_name, new_name, editor_email)
    return { success: false, error: 'Author names cannot be blank' } if old_name.blank? || new_name.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      author = book['author'].to_s.strip
      next if author.blank?
      
      if author.downcase == old_name.downcase
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'author',
          author,
          new_name,
          editor_email,
          "Renamed author: '#{old_name}' → '#{new_name}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_name: author,
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

  # Calculate Levenshtein similarity (0 to 1)
  def self.levenshtein_similarity(str1, str2)
    distance = levenshtein_distance(str1, str2)
    max_length = [str1.length, str2.length].max
    return 1.0 if max_length == 0
    1.0 - (distance.to_f / max_length)
  end

  # Calculate Levenshtein distance
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
