class CategoriesController < ApplicationController

  def index
    @categories = category_slug_pairs
    respond_to do |format|
      format.html
      format.json do
        query = params[:q].to_s.strip
        letter = params[:letter].to_s.strip
        categories = @categories
        if query.present?
          categories = categories.select { |c| c[:name].downcase.include?(query.downcase) }
        end
        if letter.present?
          categories = categories.select { |c| c[:name].start_with?(letter) }
        end
        render json: categories
      end
    end
  end

  def show
    category_name = resolve_category_slug(params[:slug])
    if category_name
      books = Book.where('categories LIKE ?', "%#{Book.escape_like(category_name)}%")
                  .includes(:book_stores => :store)
      sort_col = params[:sort].presence_in(%w[name author publisher library year]) || 'name'
      sort_dir = params[:direction].presence_in(%w[asc desc]) || 'asc'
      books = books.order("#{sort_col} #{sort_dir}")
      @books = Kaminari.paginate_array(books).page(params[:page]).per(8)
      @category_name = category_name
    else
      @books = Kaminari.paginate_array([]).page(params[:page]).per(8)
      @category_name = nil
    end
    respond_to do |format|
      format.html
      format.js { render 'books/load_more' }
    end
  end

end
