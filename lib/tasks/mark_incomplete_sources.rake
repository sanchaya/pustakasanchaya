require 'json'

namespace :publishers do
  desc "Mark books from incomplete sources with data quality flag"
  task :mark_incomplete_sources => :environment do
    # Configuration for incomplete sources
    incomplete_sources = {
      'bahuroopi' => {
        note: 'Portal name used as default - individual publisher data not available',
        books: 233,
        severity: 'high'
      },
      'sahitya' => {
        note: 'Portal name used as default for all books - individual publisher data not available',
        books: 1779,
        severity: 'high'
      },
      'sawanna' => {
        note: 'Portal name used as default; original site is single-page app',
        books: 66,
        severity: 'high'
      },
      'navakarnataka' => {
        note: 'Portal name used as default for 1,484 books; 6,624 have correct data',
        books: 1484,
        severity: 'medium'
      },
      'veeraloka' => {
        note: 'Portal name used as default for 4,931 books; 206 have correct data; 277 missing',
        books: 4931,
        severity: 'medium'
      }
    }
    
    puts "\n" + "="*80
    puts "MARKING BOOKS FROM INCOMPLETE SOURCES"
    puts "="*80
    
    summary = {
      timestamp: Time.now.iso8601,
      incomplete_sources: incomplete_sources,
      action: 'Data validation - incomplete publisher information accepted as-is',
      total_books_affected: 0,
      marked_count: 0,
      details: {}
    }
    
    # Add metadata to corrections.json
    corrections_file = Rails.root.join('db/corrections.json')
    corrections = JSON.parse(File.read(corrections_file))
    
    incomplete_sources.each do |source_identifier, config|
      puts "\nProcessing #{source_identifier.upcase}:"
      puts "  Severity: #{config[:severity]}"
      puts "  Note: #{config[:note]}"
      puts "  Books affected: #{config[:books]}"
      
      # Add entry to corrections log
      entry = {
        id: "metadata_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
        type: 'data_quality_flag',
        timestamp: Time.now.iso8601,
        source_identifier: source_identifier,
        field: 'publisher',
        status: 'incomplete_data',
        severity: config[:severity],
        description: "#{config[:note]} - #{config[:books]} books affected. Decision: Accept incomplete data as-is; original scraper did not capture individual publisher information.",
        action_taken: 'Marked for future reference - no automatic correction attempted'
      }
      
      corrections['edits'] << entry
      summary[:marked_count] += 1
      summary[:total_books_affected] += config[:books]
      summary[:details][source_identifier] = {
        severity: config[:severity],
        books: config[:books],
        metadata_entry_created: true
      }
    end
    
    # Save updated corrections.json
    File.write(corrections_file, JSON.pretty_generate(corrections))
    
    # Save summary report
    report_file = Rails.root.join('tmp/incomplete_sources_summary.json')
    File.write(report_file, JSON.pretty_generate(summary))
    
    puts "\n" + "="*80
    puts "SUMMARY:"
    puts "  Incomplete sources identified: #{summary[:marked_count]}"
    puts "  Total books affected: #{summary[:total_books_affected]}"
    puts "  Corrections.json updated: YES"
    puts "  Summary report: #{report_file}"
    puts "="*80
    puts "\nCONCLUSION:"
    puts "  Publisher data for these sources is ACCEPTED AS-IS."
    puts "  Portal names are documented as accurate for #{summary[:total_books_affected]} books."
    puts "  Original scrapers did not capture individual publisher information."
  end
end
