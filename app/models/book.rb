class Book

  BASE_SEARCH_URL = 'http://samooha.sanchaya.net/search.json?search='

  def self.search params
    search_items = params.squish
    full_url = "#{BASE_SEARCH_URL}#{search_items}"
    parsed_url = URI.parse(URI.encode(full_url))
    response = HTTParty.get parsed_url
    return response.body
  end
end