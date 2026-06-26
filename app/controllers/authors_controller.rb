class AuthorsController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        authors = author_slug_pairs
        query = params[:q].to_s.strip
        letter = params[:letter].to_s.strip
        if query.present?
          authors = authors.select { |a| a[:name].downcase.include?(query.downcase) }
        end
        if letter.present?
          authors = authors.select { |a| a[:name].start_with?(letter) }
        end
        render json: authors
      end
    end
  end

  def show
    @author_name = resolve_author_slug(params[:slug])
    unless @author_name
      render file: 'public/404.html', status: :not_found and return
    end
    @books = Book.where(author: @author_name).includes(:book_stores => :store)
    sort_col = params[:sort].presence_in(%w[name author publisher library year]) || 'name'
    sort_dir = params[:direction].presence_in(%w[asc desc]) || 'asc'
    @books = @books.order("#{sort_col} #{sort_dir}")
    @books = Kaminari.paginate_array(@books).page(params[:page]).per(20)
  end
end
