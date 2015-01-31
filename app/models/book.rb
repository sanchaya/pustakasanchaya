class Book

  BASE_SEARCH_URL = 'http://localhost:3000/search.json?search='

  def self.search params
    search_items = params.squish
    response = HTTParty.get("#{BASE_SEARCH_URL}#{search_items}")
     return response.body
  end
end