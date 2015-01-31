class BooksController < ApplicationController

  def index
   @books = params && params[:search] ? JSON.parse(Book.search(params[:search])) : {}
  end
end
