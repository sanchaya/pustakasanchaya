namespace :deduplicate do
  desc "Merge TotalKannada internal duplicates"
  task total_kannada: :environment do
    puts "=== Deduplicating TotalKannada ==="

    duplicates = Book.where(source: 'TotalKannada')
      .group(:name, :author)
      .having('count(*) > 1')
      .pluck(:name, :author)

    puts "Found #{duplicates.size} duplicate name+author pairs in TotalKannada"

    merged = 0
    duplicates.each do |name, author|
      books = Book.where(source: 'TotalKannada', name: name, author: author).order(:created_at)
      next if books.size < 2

      keeper = books.max_by do |b|
        score = 0
        score += 10 if b.categories.present? && b.categories != '--- []'
        score += 5 if b.year.present? && b.year != '0'
        score += 3 if b.publisher.present?
        score += 2 if b.archive_url.present?
        score += 1 if b.created_at.present?
        score
      end

      books.each do |book|
        next if book.id == keeper.id
        
        # Merge categories
        keeper_cats = Book.parse_categories_string(keeper.categories)
        dup_cats = Book.parse_categories_string(book.categories)
        combined = (keeper_cats + dup_cats).uniq
        keeper.update_column(:categories, Book.serialize_categories(combined)) if combined != keeper_cats

        # Fill missing fields
        [:publisher, :year, :book_link, :library, :thumbnail, :archive_url].each do |field|
          if keeper[field].blank? && book[field].present?
            keeper.update_column(field, book[field])
          end
        end

        # Merge book_stores
        book.book_stores.each do |bs|
          existing = keeper.book_stores.find_by(store_id: bs.store_id)
          if existing
            existing.update(
              store_url: bs.store_url.presence || existing.store_url,
              price: bs.price.presence || existing.price,
              availability: bs.availability.presence || existing.availability
            )
          else
            keeper.book_stores.create!(store_id: bs.store_id, store_url: bs.store_url, price: bs.price, availability: bs.availability)
          end
        end

        Correction.where(source_identifier: book.source_identifier).update_all(source_identifier: keeper.source_identifier)
        book.destroy
        merged += 1
      end
    end

    puts "Merged: #{merged} TotalKannada books"
    puts "Total books now: #{Book.count}"
  end
end