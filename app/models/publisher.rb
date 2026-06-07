require 'set'

class Publisher
  # Extract and deduplicate all publishers from books
  def self.all_publishers
    all_books = load_all_books
    publishers = Set.new
    
    all_books.each do |book|
      publisher = book['publisher'].to_s.strip
      next if publisher.blank?
      
      publishers << publisher
    end
    
    publishers.sort
  end

  # Get all unique publishers with book counts
  def self.all_with_counts
    all_books = load_all_books
    publisher_counts = {}
    
    all_books.each do |book|
      publisher = book['publisher'].to_s.strip
      next if publisher.blank?
      
      publisher_counts[publisher] ||= 0
      publisher_counts[publisher] += 1
    end
    
    publisher_counts.sort_by { |_k, v| -v }
  end

  # Find similar publishers
  def self.find_similar(publisher_name, threshold = 0.85)
    return [] if publisher_name.blank?
    
    all = all_publishers
    publisher_name = publisher_name.strip.downcase
    
    similar = all.select do |other|
      other_lower = other.downcase
      
      # Skip exact match
      next false if publisher_name == other_lower
      
      # Levenshtein distance
      similarity = levenshtein_similarity(publisher_name, other_lower)
      
      # Fuzzy matching
      fuzzy = other_lower.include?(publisher_name) || publisher_name.include?(other_lower)
      
      similarity >= threshold || fuzzy
    end
    
    similar.sort_by { |other| -levenshtein_similarity(publisher_name, other.downcase) }
  end

  # Merge two publishers
  def self.merge(old_publisher, new_publisher, editor_email)
    return { success: false, error: 'Publishers cannot be blank' } if old_publisher.blank? || new_publisher.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      publisher = book['publisher'].to_s.strip
      next if publisher.blank?
      
      if publisher.downcase == old_publisher.downcase
        old_value = publisher
        new_value = new_publisher
        
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'publisher',
          old_value,
          new_value,
          editor_email,
          "Merged publisher: '#{old_publisher}' → '#{new_publisher}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_publisher: old_value,
          new_publisher: new_value
        }
      end
    end
    
    {
      success: true,
      merged_from: old_publisher,
      merged_to: new_publisher,
      affected_count: affected_books.length,
      affected_books: affected_books
    }
  end

  # Rename a publisher
  def self.rename(old_name, new_name, editor_email)
    return { success: false, error: 'Publisher names cannot be blank' } if old_name.blank? || new_name.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      publisher = book['publisher'].to_s.strip
      next if publisher.blank?
      
      if publisher.downcase == old_name.downcase
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'publisher',
          publisher,
          new_name,
          editor_email,
          "Renamed publisher: '#{old_name}' → '#{new_name}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_name: publisher,
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
