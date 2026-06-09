class Category
  def self.all_categories
    Book.all_categories
  end

  def self.all_with_counts
    Book.category_counts.to_a
  end

  def self.find_similar(category_name, threshold = 0.85)
    return [] if category_name.blank?
    category_name_lower = category_name.strip.downcase
    all = all_categories
    similar = all.select do |other|
      other_lower = other.downcase
      next false if category_name_lower == other_lower
      similarity = levenshtein_similarity(category_name_lower, other_lower)
      fuzzy = other_lower.include?(category_name_lower) || category_name_lower.include?(other_lower)
      similarity >= threshold || fuzzy
    end
    similar.sort_by { |other| -levenshtein_similarity(category_name_lower, other.downcase) }
  end

  def self.merge(old_category, new_category, editor_email)
    old_category = old_category.strip
    new_category = new_category.strip
    return { success: false, error: 'Categories cannot be blank' } if old_category.blank? || new_category.blank?
    candidates = Book.where("categories LIKE ?", "%#{escape_like(old_category)}%")
    count = 0
    candidates.find_each do |book|
      cats = Book.parse_categories_string(book.categories)
      next unless cats.include?(old_category)
      cats.map! { |c| c == old_category ? new_category : c }
      cats.uniq!
      book.update_column(:categories, Book.serialize_categories(cats))
      Correction.record_edit(book.source_identifier, 'category', old_category, new_category, editor_email, "Merged category: '#{old_category}' → '#{new_category}'")
      count += 1
    end
    Book.bump_search_cache
    { success: true, merged_from: old_category, merged_to: new_category, affected_count: count }
  end

  def self.rename(old_name, new_name, editor_email)
    old_name = old_name.strip
    new_name = new_name.strip
    return { success: false, error: 'Category names cannot be blank' } if old_name.blank? || new_name.blank?
    candidates = Book.where("categories LIKE ?", "%#{escape_like(old_name)}%")
    count = 0
    candidates.find_each do |book|
      cats = Book.parse_categories_string(book.categories)
      next unless cats.include?(old_name)
      cats.map! { |c| c == old_name ? new_name : c }
      book.update_column(:categories, Book.serialize_categories(cats))
      Correction.record_edit(book.source_identifier, 'category', old_name, new_name, editor_email, "Renamed category: '#{old_name}' → '#{new_name}'")
      count += 1
    end
    Book.bump_search_cache
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
    Rails.logger.warn "[merge_multiple] No matches found for categories: #{unmatched.inspect}" if unmatched.any?
    { success: true, merged_count: total, unmatched: unmatched }
  end

  def self.escape_like(str)
    str.gsub(/[\\%_]/) { |m| "\\#{m}" }
  end

  private

  def self.levenshtein_similarity(str1, str2)
    distance = levenshtein_distance(str1, str2)
    max_length = [str1.length, str2.length].max
    return 1.0 if max_length == 0
    1.0 - (distance.to_f / max_length)
  end

  def self.levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 2) }
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
