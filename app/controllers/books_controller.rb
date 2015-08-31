class BooksController < ApplicationController

  def index
    begin
		books = params && params[:search] && !params[:search].blank? ? JSON.parse(Book.search(params[:search])) : {}
		@books = Kaminari.paginate_array(books).page(params[:page]).per(8) 
    rescue
		@books = {}
    end
end
end
