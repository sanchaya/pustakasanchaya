require 'json'
require 'net/http'
require 'nokogiri'

namespace :publishers do
  desc "Scrape real publisher data from individual book pages for all sources"
  task :scrape_all_sources => :environment do
    sources = {
      sahitya: { file: 'db/sahitya_books.json', portal_name: 'Sahitya Books', url_domain: 'sahityabooks.com' },
      veeraloka: { file: 'db/veeraloka_books.json', portal_name: 'Veeraloka Books', url_domain: 'veeraloka.com' },
      navakarnataka: { file: 'db/navakarnataka_books.json', portal_name: 'Navakarnataka Publications', url_domain: 'navakarnataka.com' },
      bahuroopi: { file: 'db/bahuroopi_books.json', portal_name: 'Bahuroopi', url_domain: 'bahuruopipublications.com' },
      sawanna: { file: 'db/sawanna_books.json', portal_name: 'Sawanna Enterprises', url_domain: 'sawanna.in' }
    }
    
    sources.each do |source_name, config|
      puts "\n" + "="*80
      puts "Processing #{source_name.to_s.upcase}"
      puts "="*80
      
      scrape_source(source_name, config)
    end
  end
  
  def scrape_source(source_name, config)
    file_path = Rails.root.join(config[:file])
    return puts "File not found: #{file_path}" unless File.exist?(file_path)
    
    data = JSON.parse(File.read(file_path))
    data = [data] unless data.is_a?(Array)
    
    # Filter books with portal name or missing publisher
    books_to_scrape = data.select do |b|
      publisher = b['publisher'].to_s.strip
      publisher.include?(config[:portal_name]) || publisher.empty?
    end
    
    puts "Total books: #{data.length}"
    puts "Books to scrape: #{books_to_scrape.length}"
    
    if books_to_scrape.empty?
      puts "No books need scraping for this source"
      return
    end
    
    scraped_data = []
    failed = []
    
    books_to_scrape.each_with_index do |book, idx|
      puts "\r[#{idx + 1}/#{books_to_scrape.length}] Scraping: #{book['name'][0..50]}..." if (idx + 1) % 10 == 0 || idx == 0
      
      result = scrape_book_page(book['book_link'], source_name)
      
      if result && result[:publisher].present?
        scraped_data << {
          name: book['name'],
          original_publisher: book['publisher'],
          scraped_publisher: result[:publisher],
          book_link: book['book_link']
        }
      else
        failed << { name: book['name'], book_link: book['book_link'] }
      end
      
      # Be nice to servers - add delay
      sleep(0.5)
    end
    
    puts "\n\nResults for #{source_name.to_s.upcase}:"
    puts "Successfully scraped: #{scraped_data.length}"
    puts "Failed: #{failed.length}"
    
    # Save results to file for validation
    output_file = Rails.root.join("tmp/scraped_publishers_#{source_name}.json")
    File.write(output_file, JSON.pretty_generate({
      source: source_name.to_s,
      total_books: data.length,
      books_to_scrape: books_to_scrape.length,
      successfully_scraped: scraped_data.length,
      failed: failed.length,
      scraped_data: scraped_data,
      failed_books: failed
    }))
    
    puts "Results saved to: #{output_file}"
  end
  
  def scrape_book_page(url, source_name)
    begin
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 10
      http.open_timeout = 10
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      
      response = http.request(request)
      
      return nil unless response.code == '200'
      
      doc = Nokogiri::HTML(response.body)
      
      # Source-specific selectors
      case source_name.to_s
      when 'sahitya'
        scrape_sahitya(doc)
      when 'veeraloka'
        scrape_veeraloka(doc)
      when 'navakarnataka'
        scrape_navakarnataka(doc)
      when 'bahuroopi'
        scrape_bahuroopi(doc)
      when 'sawanna'
        scrape_sawanna(doc)
      else
        nil
      end
    rescue => e
      nil
    end
  end
  
  def scrape_sahitya(doc)
    # Try multiple selectors for publisher
    publisher = doc.css('.product-meta .product-publisher, .book-publisher, [itemprop="publisher"]').text.strip
    publisher = doc.css('th:contains("Publisher") + td').text.strip if publisher.empty?
    publisher = doc.xpath('//text()[contains(., "Publisher")]/../following-sibling::td/text()').first&.text&.strip if publisher.empty?
    
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_veeraloka(doc)
    # WooCommerce style
    publisher = doc.css('.product-meta-publisher, .woocs_products_list_price, [data-attribute*="publisher"]').text.strip
    publisher = doc.css('th:contains("Publisher") + td').text.strip if publisher.empty?
    publisher = doc.css('.product-attributes table tr').find { |tr| tr.text.include?('Publisher') }&.css('td')&.last&.text&.strip if publisher.empty?
    
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_navakarnataka(doc)
    # Try multiple patterns
    publisher = doc.css('.product-publisher, .publisher, [itemprop="publisher"]').text.strip
    publisher = doc.css('th:contains("Publisher") + td').text.strip if publisher.empty?
    
    # Look for "Publisher:" text followed by value
    doc.xpath('//text()[contains(., "Publisher")]').each do |node|
      next_text = node.parent.parent.css('td')&.last&.text&.strip
      publisher = next_text if next_text.present? && next_text.length < 100
      break if publisher.present?
    end
    
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_bahuroopi(doc)
    # Try multiple selectors
    publisher = doc.css('.product-publisher, .publisher-name, [itemprop="publisher"]').text.strip
    publisher = doc.css('th:contains("Publisher") + td').text.strip if publisher.empty?
    
    # Look in description or product details
    doc.xpath('//text()[contains(., "Publisher:")]').each do |node|
      parent_text = node.parent.text.strip
      if parent_text.include?('Publisher:')
        publisher = parent_text.split('Publisher:')[1]&.split(/\n|,|;/)&.first&.strip
        break if publisher.present? && publisher.length < 100
      end
    end
    
    { publisher: publisher } if publisher.present?
  end
  
  def scrape_sawanna(doc)
    # Try multiple patterns
    publisher = doc.css('.product-publisher, .publisher, [itemprop="publisher"]').text.strip
    publisher = doc.css('th:contains("Publisher") + td').text.strip if publisher.empty?
    
    # Look for labeled publisher field
    doc.xpath('//text()[contains(., "Publisher")]').each do |node|
      parent = node.parent
      sibling_text = parent.next_sibling&.text&.strip
      publisher = sibling_text if sibling_text.present? && sibling_text.length < 100 && !sibling_text.include?('₹')
      break if publisher.present?
    end
    
    { publisher: publisher } if publisher.present?
  end
end
