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
  books = JSON.parse(Book.category_books(params[:id]))
  @books = Kaminari.paginate_array(books).page(params[:page]).per(8) 
rescue
  @books = {}
end
end

end
