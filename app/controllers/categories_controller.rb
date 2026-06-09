class CategoriesController < ApplicationController

  def index
    @categories = Book.all_categories.map.with_index(1) do |name, i|
      { 'id' => i.to_s, 'kn' => name }
    end
  end

  def show
    categories = Book.all_categories
    index = params[:id].to_i - 1
    if index >= 0 && index < categories.length
      category_name = categories[index]
      books = Book.where('categories LIKE ?', "%#{Book.escape_like(category_name)}%")
                  .select(:id, :name, :author, :publisher, :library, :year, :book_link, :archive_url, :thumbnail, :source_identifier)
      @books = Kaminari.paginate_array(books).page(params[:page]).per(8)
    else
      @books = Kaminari.paginate_array([]).page(params[:page]).per(8)
    end
    respond_to do |format|
      format.html
      format.js { render 'books/load_more' }
    end
  end

end
