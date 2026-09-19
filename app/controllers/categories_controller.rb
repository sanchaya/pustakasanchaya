class CategoriesController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json do
        begin
          categories = category_slug_pairs
          query = params[:q].to_s.strip
          letter = params[:letter].to_s.strip
          if query.present?
            categories = categories.select { |c| c[:name].downcase.include?(query.downcase) }
          end
          if letter.present?
            categories = categories.select { |c| c[:name].start_with?(letter) }
          end
          render json: categories
        rescue StandardError => e
          Rails.logger.error "Categories JSON error: #{e.message}\n#{e.backtrace.join("\n")}"
          render json: { error: 'Failed to load categories' }, status: 500
        end
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
