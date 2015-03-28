class BooksController < ApplicationController

  def index
    begin
     @books = params && params[:search] && !params[:search].blank? ? JSON.parse(Book.search(params[:search])) : {}
   rescue
    @books = {}
  end
end
end
