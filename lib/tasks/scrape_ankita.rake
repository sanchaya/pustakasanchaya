require 'open-uri'
require 'nokogiri'
require 'json'

namespace :ankita do
  desc 'Scrape books from ankitapustaka.com'
  task :scrape => :environment do
    CATEGORIES = {
      'ಸಣ್ಣ ಕಥೆ' => '10-sanna-kathe',
      'ಕಾದಂಬರಿ' => '11-kadambari',
      'ಕವನ ಸಂಕಲನ' => '12-kavana_sankalana',
      'ನಾಟಕ' => '13-nataka',
      'ವಿಮರ್ಶೆ' => '14-vimarshe',
      'ಸಂಸ್ಕೃತಿ ಚಿಂತನ ಬರಹಗಳು' => '15-samskruthi_chinthana_barahagalu',
      'ಲಲಿತ ಪ್ರಬಂಧಗಳು' => '16-lalitha_prabhandagalu',
      'ಪತ್ರಿಕೋದ್ಯಮ' => '17-pathrikodyama',
      'ಆತ್ಮಕಥನ' => '18-athmakathana',
      'ವಿಜ್ಞಾನ' => '19-vignanana',
      'ಪ್ರವಾಸ ಕಥನ' => '20-pravasha_kathana',
      'ಅಧ್ಯಾತ್ಮ' => '21-adhyathma',
      'ಮಕ್ಕಳ ಸಾಹಿತ್ಯ' => '22-makkala_sahithya',
      'ಸಮಗ್ರ ಸಾಹಿತ್ಯ' => '23-samgra_sahithya',
      'ಸಂಕೀರ್ಣ' => '24-sankeerna'
    }

    BASE_URL = 'https://ankitapustaka.com'
    all_books = {}
    category_map = {}

    CATEGORIES.each do |cat_name, cat_slug|
      page = 1
      loop do
        url = "#{BASE_URL}/#{cat_slug}"
        url += "?page=#{page}" if page > 1

        puts "Fetching #{cat_name} page #{page}: #{url}"
        begin
          html = open(url, 'User-Agent' => 'Mozilla/5.0').read
        rescue => e
          puts "  ERROR fetching #{url}: #{e.message}"
          break
        end

        doc = Nokogiri::HTML(html)
        articles = doc.css('article.product-miniature')

        if articles.empty?
          puts "  No products found on page #{page}, done with #{cat_name}"
          break
        end

        articles.each do |article|
          product_id = article['data-id-product']
          next if product_id.nil?

          # Skip if already scraped (dedup by product ID)
          if all_books[product_id]
            # Add this category to existing book
            all_books[product_id]['categories'] ||= []
            all_books[product_id]['categories'] << cat_name unless all_books[product_id]['categories'].include?(cat_name)
            next
          end

          # Extract title
          title_el = article.at_css('h3[itemprop="name"] a')
          title = title_el ? title_el['title'].to_s.strip : ''
          book_link = title_el ? title_el['href'].to_s.strip : ''

          # Extract price
          price_el = article.at_css('span[itemprop="price"]')
          price = price_el ? price_el.text.strip : ''

          # Extract description block (has author, pages, ISBN, etc.)
          desc_el = article.at_css('div.product-desc[itemprop="description"]')
          desc_text = ''
          author = ''
          pages = ''
          isbn = ''
          book_number = ''
          binding_type = ''

          if desc_el
            paragraphs = desc_el.css('p').map { |p| p.text.strip }.reject(&:empty?)
            desc_text = paragraphs.join("\n")

            # First paragraph is usually the author
            if paragraphs.any?
              author_line = paragraphs[0]
              # Clean author: remove "ಮೂಲ:" prefix, "ಅನು:" prefix, etc.
              author = author_line.strip
            end

            paragraphs.each do |p|
              if p =~ /ಪುಟಗಳು\s*[:\s]*(\d+)/
                pages = $1
              elsif p =~ /ISBN\s*[:\s]*([\d\-xX]+)/
                isbn = $1.strip
              elsif p =~ /ಪುಸ್ತಕದ ಸಂಖ್ಯೆ\s*[:\s]*([\d]+)/
                book_number = $1
              elsif p =~ /ಬೈಂಡಿಂಗ್\s*[:\s]*(.*)/
                binding_type = $1.strip
              end
            end
          end

          # Extract thumbnail
          img_el = article.at_css('img.first-image')
          thumbnail = img_el ? img_el['src'].to_s.strip : ''

          # Split title into Kannada and English parts
          name_parts = title.split('/')
          name_kannada = name_parts[0].to_s.strip
          name_english = name_parts[1..-1].to_a.join('/').strip if name_parts.length > 1

          all_books[product_id] = {
            'name' => name_kannada,
            'name_english' => name_english || '',
            'author' => author,
            'publisher' => 'ಅಂಕಿತ ಪುಸ್ತಕ',
            'library' => 'Ankita Pustaka',
            'book_link' => book_link,
            'price' => price,
            'pages' => pages,
            'isbn' => isbn,
            'book_number' => book_number,
            'binding' => binding_type,
            'thumbnail' => thumbnail,
            'categories' => [cat_name],
            'source_identifier' => "ankita_#{product_id}",
            'year' => nil,
            'archive_url' => nil
          }
        end

        puts "  Found #{articles.length} products, total unique so far: #{all_books.length}"

        # Check if there's a next page
        next_link = doc.at_css('a[rel="next"]') || doc.at_css('.pagination a:contains("Next")')
        if next_link.nil?
          # Also check by looking for page links
          page_links = doc.css('.pagination li a').map { |a| a.text.strip }
          has_next = page_links.include?((page + 1).to_s)
          unless has_next
            puts "  No next page, done with #{cat_name}"
            break
          end
        end

        page += 1
        sleep 0.5 # Be polite
      end

      puts "#{cat_name}: done. Total unique books: #{all_books.length}"
      puts "---"
    end

    books_array = all_books.values
    output_path = Rails.root.join('db', 'ankita_pustaka_books.json')
    File.write(output_path, JSON.pretty_generate(books_array))
    puts "\n=== DONE ==="
    puts "Total unique books: #{books_array.length}"
    puts "Saved to: #{output_path}"
  end
end
