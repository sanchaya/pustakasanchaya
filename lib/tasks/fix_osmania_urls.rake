namespace :fix do
  desc "Fix oudl_osmania_ac_in URLs to oudl.osmania.ac.in across all fields"
  task osmania_urls: :environment do
    fixed = 0

    Book.find_each do |book|
      changed = false

      %w[book_link archive_url metadata].each do |field|
        val = book.send(field)
        next if val.blank?
        new_val = val.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        if new_val != val
          book.update_column(field, new_val)
          changed = true
          puts "Fixed #{field} for book #{book.id}: #{val} -> #{new_val}"
        end
      end

      fixed += 1 if changed
    end

    puts "Fixed #{fixed} books"

    bs_fixed = 0
    BookStore.find_each do |bs|
      next if bs.store_url.blank?
      new_url = bs.store_url.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
      if new_url != bs.store_url
        bs.update_column(:store_url, new_url)
        bs_fixed += 1
        puts "Fixed book_store #{bs.id}: #{bs.store_url} -> #{new_url}"
      end
    end

    puts "Fixed #{bs_fixed} book_stores"
    puts "Done!"
  end
end
