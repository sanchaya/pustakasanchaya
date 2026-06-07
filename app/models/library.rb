require 'set'

class Library
  # Get all unique libraries from books
  def self.all_libraries
    all_books = load_all_books
    libraries = Set.new
    
    all_books.each do |book|
      library = book['library'].to_s.strip
      next if library.blank?
      
      libraries << library
    end
    
    libraries.sort
  end

  # Get all unique libraries with book counts
  def self.all_with_counts
    all_books = load_all_books
    library_counts = {}
    
    all_books.each do |book|
      library = book['library'].to_s.strip
      next if library.blank?
      
      library_counts[library] ||= 0
      library_counts[library] += 1
    end
    
    library_counts.sort_by { |_k, v| -v }
  end

  # Find similar libraries
  def self.find_similar(library_name, threshold = 0.85)
    return [] if library_name.blank?
    
    all = all_libraries
    library_name_lower = library_name.strip.downcase
    
    similar = all.select do |other|
      other_lower = other.downcase
      
      # Skip exact match
      next false if library_name_lower == other_lower
      
      # Levenshtein distance
      similarity = levenshtein_similarity(library_name_lower, other_lower)
      
      # Fuzzy matching
      fuzzy = other_lower.include?(library_name_lower) || library_name_lower.include?(other_lower)
      
      similarity >= threshold || fuzzy
    end
    
    similar.sort_by { |other| -levenshtein_similarity(library_name_lower, other.downcase) }
  end

  # Merge two libraries (replace old_library with new_library)
  def self.merge(old_library, new_library, editor_email)
    return { success: false, error: 'Libraries cannot be blank' } if old_library.blank? || new_library.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      library = book['library'].to_s.strip
      next if library.blank?
      
      if library.downcase == old_library.downcase
        old_value = library
        new_value = new_library
        
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'library',
          old_value,
          new_value,
          editor_email,
          "Merged library: '#{old_library}' → '#{new_library}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_library: old_value,
          new_library: new_value
        }
      end
    end
    
    {
      success: true,
      merged_from: old_library,
      merged_to: new_library,
      affected_count: affected_books.length,
      affected_books: affected_books
    }
  end

  # Rename a library
  def self.rename(old_name, new_name, editor_email)
    return { success: false, error: 'Library names cannot be blank' } if old_name.blank? || new_name.blank?
    
    all_books = load_all_books
    affected_books = []
    
    all_books.each do |book|
      library = book['library'].to_s.strip
      next if library.blank?
      
      if library.downcase == old_name.downcase
        # Record correction
        Correction.record_edit(
          book['source_identifier'],
          'library',
          library,
          new_name,
          editor_email,
          "Renamed library: '#{old_name}' → '#{new_name}'"
        )
        
        affected_books << {
          source_identifier: book['source_identifier'],
          title: book['name'],
          old_name: library,
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
