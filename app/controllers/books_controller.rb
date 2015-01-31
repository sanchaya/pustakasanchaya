class BooksController < ApplicationController

  def index
    begin
     @books = params && params[:search] ? JSON.parse(Book.search(params[:search])) : {}
   rescue
    @books = {}
  end
end
end
