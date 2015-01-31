class BooksController < ApplicationController

  def index
   @books = JSON.parse Book.search(params[:search])#.page(params[:page])
   p @books
   p @books.first
   
  end
end
