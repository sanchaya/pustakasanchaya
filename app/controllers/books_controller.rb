class BooksController < ApplicationController

  def index
   @books = Book.search(params[:search])#.page(params[:page])
  end
end
