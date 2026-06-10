require 'json'

namespace :publishers do
  desc "Analyze publisher data completeness across all sources"
  task :analyze_sources => :environment do
    json_dir = Rails.root.join('db')
    
    # Exclude archive.org collections
    excluded_files = ['servants_of_knowledge_books.json', 'jai_gyan_books.json']
    
    sources = Dir.glob(json_dir.join('*_books.json'))
      .map { |f| File.basename(f) }
      .reject { |f| excluded_files.include?(f) }
      .sort
    
    puts "Analyzing publisher data across #{sources.length} sources\n"
    puts "="*80
    
    total_books = 0
    total_with_publisher = 0
    
    sources.each do |file|
      path = json_dir.join(file)
      
      begin
        data = JSON.parse(File.read(path))
        data = [data] unless data.is_a?(Array)
        
        count = data.length
        with_publisher = data.count { |b| b['publisher'].present? && b['publisher'].strip != '' }
        without_publisher = count - with_publisher
        pct = count > 0 ? (with_publisher.to_f / count * 100).round(1) : 0
        
        total_books += count
        total_with_publisher += with_publisher
        
        source_name = file.gsub('_books.json', '').gsub('_', ' ').capitalize
        
        puts "\n#{source_name}:"
        puts "  Total books: #{count}"
        puts "  With publisher: #{with_publisher} (#{pct}%)"
        puts "  Without publisher: #{without_publisher}"
        
        # Sample missing publisher books
        if without_publisher > 0 && without_publisher <= 5
          missing_names = data.select { |b| b['publisher'].blank? }.map { |b| b['name'] }
          puts "  Missing publisher for: #{missing_names.join(', ')}"
        end
      rescue => e
        puts "\nERROR reading #{file}: #{e.message}"
      end
    end
    
    puts "\n" + "="*80
    puts "TOTAL ACROSS ALL SOURCES (excluding archive.org):"
    puts "Total books: #{total_books}"
    puts "With publisher: #{total_with_publisher} (#{(total_with_publisher.to_f / total_books * 100).round(1)}%)"
    puts "Without publisher: #{total_books - total_with_publisher}"
  end
  
  desc "Check which scrapers are defaulting to portal name as publisher"
  task :check_defaults => :environment do
    json_dir = Rails.root.join('db')
    excluded_files = ['servants_of_knowledge_books.json', 'jai_gyan_books.json']
    
    sources = Dir.glob(json_dir.join('*_books.json'))
      .map { |f| File.basename(f) }
      .reject { |f| excluded_files.include?(f) }
      .sort
    
    puts "Checking for portal-name-as-publisher pattern\n"
    puts "="*80
    
    sources.each do |file|
      path = json_dir.join(file)
      source_name = file.gsub('_books.json', '')
      
      begin
        data = JSON.parse(File.read(path))
        data = [data] unless data.is_a?(Array)
        
        # Check if majority uses source name as publisher
        publisher_counts = data.group_by { |b| b['publisher'] }.map { |p, books| [p, books.length] }.sort_by { |_, count| -count }
        
        top_publisher = publisher_counts[0]
        if top_publisher && (top_publisher[0].include?(source_name.capitalize) || top_publisher[0].include?(source_name.gsub('_', ' ').capitalize))
          pct = (top_publisher[1].to_f / data.length * 100).round(1)
          puts "\n#{source_name.upcase}:"
          puts "  #{top_publisher[1]} books (#{pct}%) have publisher = '#{top_publisher[0]}' (portal name!)"
          puts "  ACTION: Need to scrape individual book pages for real publisher"
        end
      rescue => e
        puts "\nERROR reading #{file}: #{e.message}"
      end
    end
  end
end
