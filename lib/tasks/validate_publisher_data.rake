require 'json'

namespace :publishers do
  desc "Validate publisher data across all sources"
  task :validate_all_sources => :environment do
    json_dir = Rails.root.join('db')
    
    # Sources configuration
    sources = {
      'akshara_prakashana' => { file: 'akshara_prakashana_books.json' },
      'ankita_pustaka' => { file: 'ankita_pustaka_books.json' },
      'bahuroopi' => { file: 'bahuroopi_books.json' },
      'beetle_bookshop' => { file: 'beetle_bookshop_books.json' },
      'google_books' => { file: 'google_books.json' },
      'granthamala' => { file: 'granthamala_books.json' },
      'harivu' => { file: 'harivu_books.json' },
      'kannadabookhouse' => { file: 'kannadabookhouse_books.json' },
      'navakarnataka' => { file: 'navakarnataka_books.json' },
      'ruthumana' => { file: 'ruthumana_books.json' },
      'sahitya' => { file: 'sahitya_books.json' },
      'sawanna' => { file: 'sawanna_books.json' },
      'totalkannada' => { file: 'totalkannada_books.json' },
      'veeraloka' => { file: 'veeraloka_books.json' }
    }
    
    validation_report = {
      timestamp: Time.now.iso8601,
      complete_sources: [],
      incomplete_sources: [],
      details: {}
    }
    
    total_books = 0
    complete_books = 0
    incomplete_books = 0
    
    sources.each do |source_name, config|
      file_path = json_dir.join(config[:file])
      
      begin
        data = JSON.parse(File.read(file_path))
        data = [data] unless data.is_a?(Array)
        
        books_count = data.length
        books_with_publisher = data.count { |b| b['publisher'].present? && b['publisher'].to_s.strip != '' }
        
        total_books += books_count
        
        publisher_counts = data.group_by { |b| b['publisher'].to_s.strip }
          .map { |p, books| { publisher: p, count: books.length } }
          .sort_by { |h| -h[:count] }
        
        source_report = {
          file: config[:file],
          total_books: books_count,
          with_publisher: books_with_publisher,
          without_publisher: books_count - books_with_publisher,
          publisher_completeness_pct: books_count > 0 ? (books_with_publisher.to_f / books_count * 100).round(1) : 0,
          top_publishers: publisher_counts.first(5)
        }
        
        # Check if portal name is default
        top_pub = publisher_counts.first
        if top_pub && (top_pub[:publisher].downcase.include?(source_name.downcase) || 
                       top_pub[:publisher].include?(source_name.gsub('_', ' ').capitalize))
          source_report[:status] = 'incomplete'
          source_report[:reason] = "#{top_pub[:count]}/#{books_count} books (#{(top_pub[:count].to_f/books_count*100).round(1)}%) default to '#{top_pub[:publisher]}'"
          validation_report[:incomplete_sources] << source_name
          incomplete_books += books_count
        else
          source_report[:status] = 'complete'
          validation_report[:complete_sources] << source_name
          complete_books += books_count
        end
        
        validation_report[:details][source_name] = source_report
      rescue => e
        validation_report[:details][source_name] = {
          file: config[:file],
          status: 'error',
          error: e.message
        }
      end
    end
    
    validation_report[:totals] = {
      total_books: total_books,
      books_with_complete_data: complete_books,
      books_with_incomplete_data: incomplete_books,
      completeness_pct: total_books > 0 ? (complete_books.to_f / total_books * 100).round(1) : 0
    }
    
    # Display report
    puts "\n" + "="*80
    puts "PUBLISHER DATA VALIDATION REPORT"
    puts "="*80
    puts "Generated: #{validation_report[:timestamp]}"
    
    puts "\nCOMPLETE SOURCES (#{validation_report[:complete_sources].length}):"
    validation_report[:complete_sources].each { |s| puts "  ✓ #{s}" }
    
    puts "\nINCOMPLETE SOURCES (#{validation_report[:incomplete_sources].length}):"
    validation_report[:incomplete_sources].each do |source_name|
      details = validation_report[:details][source_name]
      puts "  ✗ #{source_name}"
      puts "    #{details[:reason]}"
    end
    
    puts "\nOVERALL STATISTICS:"
    puts "  Total books: #{validation_report[:totals][:total_books]}"
    puts "  Complete sources: #{validation_report[:totals][:books_with_complete_data]} books (#{validation_report[:totals][:completeness_pct]}%)"
    puts "  Incomplete sources: #{validation_report[:totals][:books_with_incomplete_data]} books"
    
    # Save full report
    report_file = Rails.root.join('tmp/publisher_validation_report.json')
    File.write(report_file, JSON.pretty_generate(validation_report))
    puts "\nFull report saved to: #{report_file}"
  end
end
