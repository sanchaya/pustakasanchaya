namespace :db do
  desc "Import all book data from JSON files to MySQL"
  task import_books: :environment do
    sources = {
      'jai_gyan_books.json'            => 'JaiGyan',
      'servants_of_knowledge_books.json' => 'ServantsOfKnowledge',
      'ankita_pustaka_books.json'       => 'AnkitaPustaka',
      'harivu_books.json'               => 'Harivu',
      'kannadabookhouse_books.json'     => 'KannadaBookHouse',
      'navakarnataka_books.json'        => 'NavaKarnataka',
      'ruthumana_books.json'            => 'Ruthumana',
      'google_books.json'               => 'GoogleBooks',
      'bahuroopi_books.json'            => 'Bahuroopi',
      'beetle_bookshop_books.json'      => 'BeetleBookshop',
      'sahitya_books.json'              => 'Sahitya',
      'totalkannada_books.json'         => 'TotalKannada',
      'veeraloka_books.json'            => 'Veeraloka',
      'granthamala_books.json'          => 'Granthamala',
      'sawanna_books.json'              => 'Sawanna',
      'akshara_prakashana_books.json'   => 'AksharaPrakashana'
    }

    total = 0
    sources.each do |filename, source_name|
      file_path = Rails.root.join('db', filename)
      next unless File.exist?(file_path)

      records = JSON.parse(File.read(file_path))
      puts "Importing #{records.length} records from #{filename}..."

      batch = []
      records.each do |rec|
        batch << {
          source_identifier: rec['source_identifier'],
          name: rec['name'],
          name_english: rec['name_english'],
          author: rec['author'],
          publisher: rec['publisher'],
          categories: rec['categories'],
          library: rec['library'] || source_name,
          year: rec['year'].to_s,
          book_link: rec['book_link'],
          archive_url: rec['archive_url'],
          metadata: rec['metadata'],
          thumbnail: rec['thumbnail'],
          language: rec['language'],
          source: source_name
        }
      end

      now = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      batch.each_slice(500) do |slice|
        values = slice.map { |r|
          si = Book.connection.quote(r[:source_identifier])
          nm = Book.connection.quote(r[:name])
          ne = Book.connection.quote(r[:name_english])
          au = Book.connection.quote(r[:author])
          pu = Book.connection.quote(r[:publisher])
          ca = Book.connection.quote(r[:categories])
          li = Book.connection.quote(r[:library])
          yr = Book.connection.quote(r[:year])
          bl = Book.connection.quote(r[:book_link])
          ar = Book.connection.quote(r[:archive_url])
          md = Book.connection.quote(r[:metadata])
          th = Book.connection.quote(r[:thumbnail])
          lg = Book.connection.quote(r[:language])
          sc = Book.connection.quote(r[:source])
          "(#{si},#{nm},#{ne},#{au},#{pu},#{ca},#{li},#{yr},#{bl},#{ar},#{md},#{th},#{lg},#{sc},#{Book.connection.quote(now)},#{Book.connection.quote(now)})"
        }.join(',')
        sql = "INSERT IGNORE INTO books (source_identifier,name,name_english,author,publisher,categories,library,year,book_link,archive_url,metadata,thumbnail,language,source,created_at,updated_at) VALUES #{values}"
        Book.connection.execute(sql)
      end

      total += records.length
    end

    puts "Imported #{total} books total."
    puts "Total books in DB: #{Book.count}"
  end

  desc "Import admin users from JSON to MySQL"
  task import_admins: :environment do
    file_path = Rails.root.join('db', 'admin_users.json')
    unless File.exist?(file_path)
      puts "admin_users.json not found. Skipping."
      return
    end

    data = JSON.parse(File.read(file_path))

    data['admins'].each do |admin_data|
      last_login = begin; Time.parse(admin_data['last_login']); rescue; nil; end
      created_at = begin; Time.parse(admin_data['created_at']); rescue; Time.now; end
      AdminUser.find_or_create_by!(email: admin_data['email']) do |u|
        u.name = admin_data['name']
        u.password_hash = admin_data['password_hash']
        u.role = admin_data['role'] || 'admin'
        u.active = admin_data['active'] != false
        u.last_login = last_login
        u.created_at = created_at
      end
      puts "Imported admin: #{admin_data['email']}"
    end

    data['invites'].each do |invite_data|
      used_at = begin; Time.parse(invite_data['used_at']); rescue; nil; end
      created_at = begin; Time.parse(invite_data['created_at']); rescue; Time.now; end
      Invite.find_or_create_by!(token: invite_data['token']) do |i|
        i.email = invite_data['email']
        i.role = invite_data['role']
        i.used = invite_data['used']
        i.used_at = used_at
        i.created_at = created_at
      end
      puts "Imported invite: #{invite_data['email']}"
    end
  end

  desc "Import corrections from JSON to MySQL"
  task import_corrections: :environment do
    file_path = Rails.root.join('db', 'corrections.json')
    unless File.exist?(file_path)
      puts "corrections.json not found. Skipping."
      return
    end

    data = JSON.parse(File.read(file_path))

    edits_count = 0
    data['edits'].each do |edit|
      ts = begin; Time.parse(edit['timestamp']); rescue; Time.now; end
      Correction.create!(
        correction_type: 'edit',
        editor: edit['editor'],
        source_identifier: edit['source_identifier'],
        field: edit['field'],
        old_value: edit['old_value'],
        new_value: edit['new_value'],
        description: edit['description'],
        timestamp: ts
      )
      edits_count += 1
    end
    puts "Imported #{edits_count} edits."

    merges_count = 0
    data['merges'].each do |merge|
      ts = begin; Time.parse(merge['timestamp']); rescue; Time.now; end
      Correction.create!(
        correction_type: 'merge',
        editor: merge['editor'],
        source_ids: merge['source_ids'].to_json,
        canonical_id: merge['canonical_id'],
        description: merge['description'],
        timestamp: ts
      )
      merges_count += 1
    end
    puts "Imported #{merges_count} merges."
  end

  desc "Import all data from JSON files to MySQL"
  task import_all: [:import_books, :import_admins, :import_corrections]
end
