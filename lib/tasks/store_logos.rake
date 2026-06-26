namespace :store do
  desc "Download all store logos to public/images/store-logos/ and update DB paths"
  task download_logos: :environment do
    dest_dir = Rails.root.join('public', 'images', 'store-logos').to_s
    FileUtils.mkdir_p(dest_dir)

    Store.active.where.not(logo: [nil, '']).order(:id).find_each do |store|
      url = store.logo.strip
      next if url.start_with?('/')

      ext = File.extname(URI.parse(url).path)
      ext = '.png' if ext.blank?
      filename = "#{store.id}#{ext}"
      filepath = File.join(dest_dir, filename)

      if File.exist?(filepath) && File.size(filepath) > 0
        puts "SKIP #{store.id} #{store.name} — already exists"
        store.update_column(:logo, "/images/store-logos/#{filename}")
        next
      end

      puts "Downloading #{store.id} #{store.name}..."
      tmpfile = filepath + ".tmp"
      system("curl", "-sL", "-o", tmpfile, "-m", "15", url)

      if File.exist?(tmpfile) && File.size(tmpfile) > 0
        mime = `file --brief --mime-type #{tmpfile}`.strip
        ext_map = {
          'image/jpeg' => '.jpg',
          'image/png'  => '.png',
          'image/gif'  => '.gif',
          'image/webp' => '.webp',
          'image/svg+xml' => '.svg',
        }
        corrected = ext_map[mime]
        if corrected
          filename = "#{store.id}#{corrected}"
          filepath = File.join(dest_dir, filename)
        end
        FileUtils.mv(tmpfile, filepath)
        store.update_column(:logo, "/images/store-logos/#{filename}")
        puts "OK   #{store.id} #{store.name} → #{filename} (#{File.size(filepath)} bytes, #{mime})"
      else
        puts "FAIL #{store.id} #{store.name} — download failed"
        FileUtils.rm_f(tmpfile)
      end
    end

    puts "Done."
  end
end
