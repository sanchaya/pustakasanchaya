class BooksController < ApplicationController

  def index
   @books = JSON.parse Book.search(params[:search])#.page(params[:page])
  end
end
