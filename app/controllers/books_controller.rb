class BooksController < ApplicationController

  def index
    begin
      if params && params[:search] && !params[:search].blank?
        books = JSON.parse(Book.search(params[:search]))
        @books = Kaminari.paginate_array(books).page(params[:page]).per(8) 
      else
        @wiki_book = JSON.parse(Book.wiki_search)
      end
    rescue
      @books = {}
    end
  end
end
