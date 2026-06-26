namespace :slugs do
  def backfill_for(type, name_col, slug_col)
    names_with_counts = case type
    when :author
      Book.where.not(author: [nil, '']).group(:author).count.sort_by { |_, c| -c }
    when :publisher
      Book.where.not(publisher: [nil, '']).group(:publisher).count.sort_by { |_, c| -c }
    end

    total = names_with_counts.length
    base_counts = Hash.new(0)
    names_with_counts.each { |name, _| base_counts[SlugHelper.slug_for(name)] += 1 }

    usage = Hash.new(0)
    names_with_counts.each_with_index do |(name, _), i|
      base = SlugHelper.slug_for(name)
      if base_counts[base] > 1
        usage[base] += 1
        slug = "#{base}-#{usage[base]}"
      else
        slug = base
      end
      Book.where(name_col => name).update_all(slug_col => slug)
      puts "  [#{i + 1}/#{total}] #{name.truncate(40)} -> #{slug}" if (i + 1) % 100 == 0 || i == total - 1
    end
  end

  desc "Backfill author_slug and publisher_slug columns for all books (with collision handling)"
  task backfill: :environment do
    puts "Backfilling author slugs..."
    backfill_for(:author, :author, :author_slug)
    puts "\nBackfilling publisher slugs..."
    backfill_for(:publisher, :publisher, :publisher_slug)
    puts "\nDone! Slugs backfilled."
  end

  desc "Warm the slug cache (pre-build slug maps and slug pairs)"
  task warm_cache: :environment do
    helper = Object.new.extend(SlugHelper)
    puts "Warming author slug map..."
    helper.author_slug_map
    puts "Warming publisher slug map..."
    helper.publisher_slug_map
    puts "Warming category slug map..."
    helper.category_slug_map
    puts "Warming author slug pairs..."
    helper.author_slug_pairs
    puts "Warming publisher slug pairs..."
    helper.publisher_slug_pairs
    puts "Warming category slug pairs..."
    helper.category_slug_pairs
    puts "Done! All slug caches warmed."
  end

  desc "Backfill slugs and warm cache (full setup)"
  task setup: [:backfill, :warm_cache]
end
