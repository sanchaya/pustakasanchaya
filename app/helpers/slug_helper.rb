module SlugHelper
  def self.slug_for(name)
    slug = name.to_s.parameterize
    slug.presence || Digest::MD5.hexdigest(name)[0..7]
  end

  def slug_for(name)
    SlugHelper.slug_for(name)
  end

  def resolve_author_slug(slug)
    names = Book.where(author_slug: slug).distinct.pluck(:author)
    return names.first if names.length == 1
    author_slug_map[slug]
  end

  def resolve_publisher_slug(slug)
    names = Book.where(publisher_slug: slug).distinct.pluck(:publisher)
    return names.first if names.length == 1
    publisher_slug_map[slug]
  end

  def resolve_category_slug(slug)
    category_slug_map[slug]
  end

  def author_slug_map
    Rails.cache.fetch("slug_map:author", expires_in: 24.hours) do
      names = Book.where.not(author: [nil, '']).distinct.pluck(:author)
      build_name_map(names)
    end
  end

  def publisher_slug_map
    Rails.cache.fetch("slug_map:publisher", expires_in: 24.hours) do
      names = Book.where.not(publisher: [nil, '']).distinct.pluck(:publisher)
      build_name_map(names)
    end
  end

  def category_slug_map
    Rails.cache.fetch("slug_map:category", expires_in: 24.hours) do
      names = Book.all_categories
      build_name_map(names)
    end
  end

  def author_slug_pairs
    Rails.cache.fetch("slug_pairs:author", expires_in: 24.hours) do
      book_counts = Book.where.not(author: [nil, '']).group(:author).count
      pub_counts = Book.where.not(author: [nil, '']).where.not(publisher: [nil, ''])
                       .group(:author).distinct.count(:publisher)
      pairs = book_counts.sort_by { |_, c| -c }
      build_slug_pairs_from(pairs, book_counts, pub_counts, :publishers)
    end
  end

  def publisher_slug_pairs
    Rails.cache.fetch("slug_pairs:publisher", expires_in: 24.hours) do
      book_counts = Book.where.not(publisher: [nil, '']).group(:publisher).count
      auth_counts = Book.where.not(publisher: [nil, '']).where.not(author: [nil, ''])
                       .group(:publisher).distinct.count(:author)
      pairs = book_counts.sort_by { |_, c| -c }
      build_slug_pairs_from(pairs, book_counts, auth_counts, :authors)
    end
  end

  def category_slug_pairs
    Rails.cache.fetch("slug_pairs:category", expires_in: 24.hours) do
      pairs = Book.all_categories.map { |n| [n, 0] }
      build_slug_pairs_from(pairs)
    end
  end

  def invalidate_slug_cache!
    keys = %w[
      slug_map:author slug_map:publisher slug_map:category
      slug_pairs:author slug_pairs:publisher slug_pairs:category
    ]
    keys.each { |k| Rails.cache.delete(k) }
  end

  private

  def build_name_map(names)
    map = {}
    counts = Hash.new(0)
    names.each do |name|
      base = SlugHelper.slug_for(name)
      if map.key?(base)
        counts[base] += 1
        map["#{base}-#{counts[base]}"] = name
      else
        map[base] = name
      end
    end
    map
  end

  def build_slug_pairs_from(names_and_counts, count_map = nil, extra_map = nil, extra_key = nil)
    base_counts = Hash.new(0)
    names_and_counts.each { |name, _| base_counts[SlugHelper.slug_for(name)] += 1 }

    usage = Hash.new(0)
    names_and_counts.map do |name, _|
      base = SlugHelper.slug_for(name)
      if base_counts[base] > 1
        usage[base] += 1
        slug = "#{base}-#{usage[base]}"
      else
        slug = base
      end
      entry = { name: name, slug: slug, books: count_map ? (count_map[name] || 0) : 0 }
      entry[extra_key] = extra_map[name] || 0 if extra_key && extra_map
      entry
    end
  end
end
