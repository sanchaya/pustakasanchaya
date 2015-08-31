class CategoriesController < ApplicationController

  def index
   begin
    @categories = JSON.parse(Book.categories)
  rescue
    @categories = {}
  end
end

def show
   begin
    @category_books = JSON.parse(Book.category_books(params[:id]))
  rescue
    @category_books = {}
  end
end

end
