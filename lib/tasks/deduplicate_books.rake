namespace :deduplicate do
  desc "Merge duplicate books by archive_url, preferring richer records"
  task books: :environment do
    puts "=== Starting Book Deduplication ==="
    puts "Time: #{Time.now}"

    # Find all archive_urls with multiple books
    duplicates = Book.where.not(archive_url: [nil, ''])
      .group(:archive_url)
      .having('count(*) > 1')
      .pluck(:archive_url)

    puts "Found #{duplicates.size} archive URLs with duplicates"

    merged = 0
    kept = 0

    duplicates.each_with_index do |archive_url, index|
      books = Book.where(archive_url: archive_url).order(:created_at)
      next if books.size < 2

      # Keep the book with most metadata (categories, year, publisher, etc.)
      # Prefer: has categories > has year > has publisher > oldest created_at
      keeper = books.max_by do |b|
        score = 0
        score += 10 if b.categories.present? && b.categories != '--- []'
        score += 5 if b.year.present? && b.year != '0'
        score += 3 if b.publisher.present?
        score += 2 if b.author.present?
        score += 1 if b.created_at.present?
        score
      end

      # Merge others into keeper
      books.each do |book|
        next if book.id == keeper.id
        
        merge_into_keeper(keeper, book)
        book.destroy
        merged += 1
      end
      kept += 1

      print "\rProcessed #{index + 1}/#{duplicates.size} | Merged: #{merged} | Kept: #{kept}"
    end

    puts "\n=== Deduplication Complete ==="
    puts "Merged: #{merged} books"
    puts "Kept unique: #{kept} books"
    puts "Total books now: #{Book.count}"
  end

  def merge_into_keeper(keeper, duplicate)
    # Merge categories
    keeper_cats = Book.parse_categories_string(keeper.categories)
    dup_cats = Book.parse_categories_string(duplicate.categories)
    combined = (keeper_cats + dup_cats).uniq
    keeper.update_column(:categories, Book.serialize_categories(combined)) if combined != keeper_cats

    # Fill missing fields from duplicate
    fields = [:author, :publisher, :year, :book_link, :library, :thumbnail, :language]
    fields.each do |field|
      if keeper[field].blank? && duplicate[field].present?
        keeper.update_column(field, duplicate[field])
      end
    end

    # Merge store associations (book_stores)
    duplicate.book_stores.each do |bs|
      existing = keeper.book_stores.find_by(store_id: bs.store_id)
      if existing
        # Keep the one with more info
        if (bs.store_url.blank? && existing.store_url.present?) || 
           (bs.price.blank? && existing.price.present?) ||
           (bs.availability.blank? && existing.availability.present?)
          # Keep existing
        else
          existing.update(
            store_url: bs.store_url.presence || existing.store_url,
            price: bs.price.presence || existing.price,
            availability: bs.availability.presence || existing.availability
          )
        end
      else
        keeper.book_stores.create!(
          store_id: bs.store_id,
          store_url: bs.store_url,
          price: bs.price,
          availability: bs.availability
        )
      end
    end

    # Merge corrections
    Correction.where(source_identifier: duplicate.source_identifier)
      .update_all(source_identifier: keeper.source_identifier)

    # Log the merge
    Rails.logger.info "[Deduplicate] Merged #{duplicate.source_identifier} into #{keeper.source_identifier} (archive_url: #{duplicate.archive_url})"
  end
end