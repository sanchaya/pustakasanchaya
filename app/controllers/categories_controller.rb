class CategoriesController < ApplicationController

  def index
    begin
      @categories = JSON.parse(Book.categories)
    rescue StandardError
      @categories = []
      flash.now[:alert] = 'Category service is temporarily unavailable. Please try again later.'
    end
  end

  def show
    begin
      books = JSON.parse(Book.category_books(params[:id]))
      @books = Kaminari.paginate_array(books).page(params[:page]).per(8)
    rescue StandardError
      @books = []
      flash.now[:alert] = 'Category service is temporarily unavailable. Please try again later.'
    end
    respond_to do |format|
      format.html
      format.js { render 'books/load_more' }
    end
  end

end
