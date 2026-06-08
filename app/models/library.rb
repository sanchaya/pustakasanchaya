class Library
  def self.all_libraries
    Book.all_libraries
  end

  def self.all_with_counts
    Book.library_counts.to_a
  end

  def self.find_similar(library_name, threshold = 0.85)
    return [] if library_name.blank?
    library_name_lower = library_name.strip.downcase
    all = all_libraries
    similar = all.select do |other|
      other_lower = other.downcase
      next false if library_name_lower == other_lower
      similarity = levenshtein_similarity(library_name_lower, other_lower)
      fuzzy = other_lower.include?(library_name_lower) || library_name_lower.include?(other_lower)
      similarity >= threshold || fuzzy
    end
    similar.sort_by { |other| -levenshtein_similarity(library_name_lower, other.downcase) }
  end

  def self.merge(old_library, new_library, editor_email)
    return { success: false, error: 'Libraries cannot be blank' } if old_library.blank? || new_library.blank?
    affected = Book.where(library: old_library)
    count = affected.count
    affected.update_all(library: new_library)
    affected.find_each do |book|
      Correction.record_edit(book.source_identifier, 'library', old_library, new_library, editor_email, "Merged library: '#{old_library}' → '#{new_library}'")
    end
    { success: true, merged_from: old_library, merged_to: new_library, affected_count: count }
  end

  def self.rename(old_name, new_name, editor_email)
    return { success: false, error: 'Library names cannot be blank' } if old_name.blank? || new_name.blank?
    affected = Book.where(library: old_name)
    count = affected.count
    affected.update_all(library: new_name)
    affected.find_each do |book|
      Correction.record_edit(book.source_identifier, 'library', old_name, new_name, editor_email, "Renamed library: '#{old_name}' → '#{new_name}'")
    end
    { success: true, renamed_from: old_name, renamed_to: new_name, affected_count: count }
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
        matrix[i][j] = [matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost].min
      end
    end
    matrix[str1.length][str2.length]
  end
end
