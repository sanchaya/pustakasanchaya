def fetch_ia_page(base_url, query, start, rows)
  params = {
    q: query,
    fl: 'identifier,title,creator,date,publisher,language,mediatype,collection,publicdate,year',
    output: 'json',
    rows: rows,
    start: start
  }
  url = "#{base_url}?#{params.to_query}"
  response = HTTParty.get(url)
  unless response.success?
    sleep 2
    response = HTTParty.get(url)
  end
  data = JSON.parse(response.body)
  [data['response']['docs'] || [], data['response']['numFound'] || 0]
end

def fetch_ia_all(base_url, query, rows = 10000)
  # IA `start` pagination is broken, but `rows` works (capped at ~10000)
  # Use rows=10000 for sub-queries with < 10k items, gets all in one call
  params = {
    q: query,
    fl: 'identifier,title,creator,date,publisher,language,mediatype,collection,publicdate,year',
    output: 'json',
    rows: rows
  }
  url = "#{base_url}?#{params.to_query}"
  response = HTTParty.get(url)
  unless response.success?
    sleep 2
    response = HTTParty.get(url)
  end
  data = JSON.parse(response.body)
  data['response']['docs'] || []
end

def map_ia_doc(doc, default_library)
  identifier = doc['identifier']
  creator = Array(doc['creator']).join(', ')
  year_raw = doc['year']
  year_str = year_raw.is_a?(Integer) ? year_raw.to_s : (year_raw&.to_s if year_raw)
  year_str ||= doc['date'].to_s[0..3] if doc['date']
  collection = Array(doc['collection'])
  library = collection.find { |c| c != 'JaiGyan' && c != 'ServantsOfKnowledge' } || default_library

  {
    'name' => doc['title'],
    'author' => creator,
    'publisher' => doc['publisher'],
    'library' => library,
    'year' => year_str,
    'book_link' => "https://archive.org/details/#{identifier}",
    'archive_url' => "https://archive.org/details/#{identifier}",
    'metadata' => "archive_url:https://archive.org/details/#{identifier}",
    'source_identifier' => identifier,
    'language' => Array(doc['language']).join(', '),
    'publicdate' => doc['publicdate']
  }
end

namespace :import do
  desc "Fetch all Kannada books from Internet Archive JaiGyan collection"
  task jai_gyan: :environment do
    require 'json'
    require 'set'

    base_url = 'https://archive.org/advancedsearch.php'
    output_path = Rails.root.join('db', 'jai_gyan_books.json')
    $stdout.sync = true

    all_books = []
    seen = Set.new
    base_query = 'collection:JaiGyan AND language:kan AND mediatype:texts -collection:gazetteofindia'

    (1908..2026).each do |year|
      query = "#{base_query} AND year:[#{year} TO #{year}]"
      docs, total = fetch_ia_page(base_url, query, 0, 1000)
      next if docs.empty?
      count = 0
      docs.each do |doc|
        id = doc['identifier']
        next if seen.include?(id)
        seen.add(id)
        all_books << map_ia_doc(doc, 'JaiGyan')
        count += 1
      end
      puts "#{year}: #{count} new (of #{total})"
    end

    docs, total = fetch_ia_page(base_url, "#{base_query} AND year:[* TO 1907]", 0, 10000)
    count = 0
    docs.each do |doc|
      id = doc['identifier']
      next if seen.include?(id)
      seen.add(id)
      all_books << map_ia_doc(doc, 'JaiGyan')
      count += 1
    end
    puts "before 1908: #{count} new (of #{total})"

    docs, total = fetch_ia_page(base_url, "#{base_query} AND -year:[* TO *]", 0, 10000)
    count = 0
    docs.each do |doc|
      id = doc['identifier']
      next if seen.include?(id)
      seen.add(id)
      all_books << map_ia_doc(doc, 'JaiGyan')
      count += 1
    end
    puts "no year: #{count} new (of #{total})"

    File.write(output_path, JSON.pretty_generate(all_books))
    puts "\nTotal: #{all_books.size} books saved to #{output_path}"
  end

  desc "Fetch all Kannada books from ServantsOfKnowledge collection on Internet Archive"
  task servants_of_knowledge: :environment do
    require 'json'
    require 'set'

    base_url = 'https://archive.org/advancedsearch.php'
    output_path = Rails.root.join('db', 'servants_of_knowledge_books.json')
    $stdout.sync = true

    all_books = []
    seen = Set.new

    jg_path = Rails.root.join('db', 'jai_gyan_books.json')
    if File.exist?(jg_path)
      existing = JSON.parse(File.read(jg_path))
      existing.each { |b| seen.add(b['source_identifier']) }
      puts "Loaded #{seen.size} existing identifiers from JaiGyan cache"
    end

    base_query = 'collection:ServantsOfKnowledge AND language:(kan OR kannada)'

    (2017..2026).each do |year|
      year_query = "#{base_query} AND publicdate:[#{year}-01-01T00:00:00Z TO #{year}-12-31T23:59:59Z]"
      docs, year_total = fetch_ia_page(base_url, year_query, 0, 0)
      puts "\n#{year}: #{year_total} total items"
      next if year_total == 0

      if year_total <= 10000
        docs = fetch_ia_all(base_url, year_query)
        count = 0
        docs.each do |doc|
          id = doc['identifier']
          next if seen.include?(id)
          seen.add(id)
          all_books << map_ia_doc(doc, 'ServantsOfKnowledge')
          count += 1
        end
        puts "  #{count} new books imported"
      else
        (1..12).each do |month|
          m = month.to_s.rjust(2, '0')
          month_query = "#{base_query} AND publicdate:[#{year}-#{m}-01T00:00:00Z TO #{year}-#{m}-31T23:59:59Z]"
          _, month_total = fetch_ia_page(base_url, month_query, 0, 0)
          next if month_total == 0

          if month_total <= 10000
            docs = fetch_ia_all(base_url, month_query)
            count = 0
            docs.each do |doc|
              id = doc['identifier']
              next if seen.include?(id)
              seen.add(id)
              all_books << map_ia_doc(doc, 'ServantsOfKnowledge')
              count += 1
            end
            puts "  #{year}-#{m}: #{count} new (of #{month_total})"
          else
            days_in_month = Date.new(year, month, -1).day
            (1..days_in_month).each do |day|
              d = day.to_s.rjust(2, '0')
              day_query = "#{base_query} AND publicdate:[#{year}-#{m}-#{d}T00:00:00Z TO #{year}-#{m}-#{d}T23:59:59Z]"
              _, day_total = fetch_ia_page(base_url, day_query, 0, 0)
              next if day_total == 0

              docs = fetch_ia_all(base_url, day_query)
              count = 0
              docs.each do |doc|
                id = doc['identifier']
                next if seen.include?(id)
                seen.add(id)
                all_books << map_ia_doc(doc, 'ServantsOfKnowledge')
                count += 1
              end
              puts "    #{year}-#{m}-#{d}: #{count} new (of #{day_total})" if count > 0
            end
          end
        end
      end
    end

    File.write(output_path, JSON.pretty_generate(all_books))
    puts "\nTotal: #{all_books.size} new ServantsOfKnowledge books saved to #{output_path}"
    puts "Total unique across both collections: #{seen.size}"
  end

  desc "Compute stats from cached JSON files and save to db/stats.json"
  task compute_stats: :environment do
    require 'json'
    require 'set'

    stats_path = Rails.root.join('db', 'stats.json')
    jg_path = Rails.root.join('db', 'jai_gyan_books.json')
    sok_path = Rails.root.join('db', 'servants_of_knowledge_books.json')

    all_books = []
    [jg_path, sok_path].each do |path|
      next unless File.exist?(path)
      all_books.concat(JSON.parse(File.read(path)))
    end

    seen = Set.new
    unique = []
    all_books.each do |b|
      id = b['source_identifier']
      next if seen.include?(id)
      seen.add(id)
      unique << b
    end

    libraries = Set.new
    authors = Set.new
    publishers = Set.new

    unique.each do |b|
      lib = b['library']
      libraries.add(lib) if lib && !lib.start_with?('fav-')

      author = b['author']
      authors.add(author) if author.is_a?(String) && !author.empty?

      pub = b['publisher']
      publishers.add(pub) if pub.is_a?(String) && !pub.empty?
    end

    lib_counts = Hash.new(0)
    unique.each do |b|
      lib = b['library']
      lib_counts[lib] += 1 if lib && !lib.start_with?('fav-')
    end

    stats = {
      'total_books' => unique.size,
      'total_libraries' => libraries.size,
      'total_authors' => authors.size,
      'total_publishers' => publishers.size,
      'libraries' => lib_counts.sort_by { |_, v| -v }.to_h
    }

    File.write(stats_path, JSON.pretty_generate(stats))
    puts "Stats saved to #{stats_path}"
    puts "  Books: #{stats['total_books']}"
    puts "  Libraries: #{stats['total_libraries']}"
    puts "  Authors: #{stats['total_authors']}"
    puts "  Publishers: #{stats['total_publishers']}"
  end

  desc "Post a collection JSON file to backend API"
  task :to_backend, [:file] => :environment do |_, args|
    require 'json'

    file = args[:file] || Rails.root.join('db', 'jai_gyan_books.json')
    backend_url = Book::BASE_URL

    unless File.exist?(file)
      puts "File not found: #{file}"
      puts "Usage: rake import:to_backend[db/jai_gyan_books.json]"
      exit 1
    end

    books = JSON.parse(File.read(file))
    puts "Posting #{books.size} books to #{backend_url}/books ..."

    books.each_slice(50) do |batch|
      response = HTTParty.post(
        "#{backend_url}/books/batch",
        body: { books: batch }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      if response.success?
        puts "  Batch posted successfully"
      else
        puts "  Batch failed: #{response.code} #{response.body}"
      end
    end

    puts "Done."
  end
end
