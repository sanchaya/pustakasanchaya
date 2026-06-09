class Author
  def self.all_authors
    Book.all_authors
  end

  def self.all_with_counts
    Book.author_counts.to_a
  end

  def self.find_similar(author_name, threshold = 0.85)
    return [] if author_name.blank?
    author_name_lower = author_name.strip.downcase
    all = all_authors
    similar = all.select do |other|
      other_lower = other.downcase
      next false if author_name_lower == other_lower
      similarity = levenshtein_similarity(author_name_lower, other_lower)
      fuzzy = other_lower.include?(author_name_lower) || author_name_lower.include?(other_lower)
      similarity >= threshold || fuzzy
    end
    similar.sort_by { |other| -levenshtein_similarity(author_name_lower, other.downcase) }
  end

  def self.merge(old_author, new_author, editor_email)
    old_author = old_author.strip
    new_author = new_author.strip
    return { success: false, error: 'Authors cannot be blank' } if old_author.blank? || new_author.blank?
    affected = Book.where(author: old_author)
    count = affected.count
    affected.update_all(author: new_author)
    Book.bump_search_cache
    affected.find_each do |book|
      Correction.record_edit(book.source_identifier, 'author', old_author, new_author, editor_email, "Merged author: '#{old_author}' → '#{new_author}'")
    end
    { success: true, merged_from: old_author, merged_to: new_author, affected_count: count }
  end

  def self.rename(old_name, new_name, editor_email)
    old_name = old_name.strip
    new_name = new_name.strip
    return { success: false, error: 'Author names cannot be blank' } if old_name.blank? || new_name.blank?
    affected = Book.where(author: old_name)
    count = affected.count
    affected.update_all(author: new_name)
    Book.bump_search_cache
    affected.find_each do |book|
      Correction.record_edit(book.source_identifier, 'author', old_name, new_name, editor_email, "Renamed author: '#{old_name}' → '#{new_name}'")
    end
    { success: true, renamed_from: old_name, renamed_to: new_name, affected_count: count }
  end

  def self.merge_multiple(source_names, target_name, editor_email)
    target_name = target_name.strip
    return { success: false, error: 'No sources or target specified' } if source_names.blank? || target_name.blank?
    total = 0
    unmatched = []
    source_names.each do |old_name|
      old_name = old_name.strip
      next if old_name == target_name
      result = merge(old_name, target_name, editor_email)
      if result[:success]
        total += result[:affected_count]
        unmatched << old_name if result[:affected_count] == 0
      else
        unmatched << old_name
      end
    end
    Rails.logger.warn "[merge_multiple] No matches found for authors: #{unmatched.inspect}" if unmatched.any?
    { success: true, merged_count: total, unmatched: unmatched }
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
