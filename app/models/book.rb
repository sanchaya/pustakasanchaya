class Book

  BASE_URL = Rails.env == "development" ? 'http://localhost:3001' : 'http://samooha.sanchaya.net'
  BASE_SEARCH_URL = Rails.env == "development" ? 'http://localhost:3001/search.json?search=' : 'http://samooha.sanchaya.net/search.json?search='
  # BASE_SEARCH_URL = 'http://samooha.sanchaya.net/search.json?search='
  # BASE_URL = 'http://samooha.sanchaya.net'

  def self.search params
    search_items = params.squish
    full_url = "#{BASE_SEARCH_URL}#{search_items}"
    parsed_url = URI.parse(URI.encode(full_url))
    response = HTTParty.get parsed_url
    return response.body
  end

  def self.wiki_search
    wiki_book_url = 'wiki_books'
    full_url = "#{BASE_URL}/#{wiki_book_url}"
    return parse_url(full_url).body
  end

  def self.categories
    full_url = "#{BASE_URL}/categories"
    parsed_url = URI.parse(URI.encode(full_url))
    response = HTTParty.get parsed_url
    return response.body
  end

  def self.category_books(id)
    full_url = "#{BASE_URL}/categories/#{id}"
    parsed_url = URI.parse(URI.encode(full_url))
    response = HTTParty.get parsed_url
    return response.body
  end


  def self.parse_url(url)
    HTTParty.get(URI.parse(URI.encode(url)))
  end

# Posting data
def self.capture_wiki_user(book_name,is_account, user_name='', book_id=nil, library=nil)
  wiki_user_url = 'wiki_user_info'
  full_url = "#{BASE_URL}/#{wiki_user_url}?book_name=#{book_name}&&is_account=#{is_account}&&user_name=#{user_name}&&book_id=#{book_id}&&library=#{library}"
  return parse_url(full_url).body
end

end
