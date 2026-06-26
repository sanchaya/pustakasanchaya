class PublishersController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        publishers = publisher_slug_pairs
        query = params[:q].to_s.strip
        letter = params[:letter].to_s.strip
        if query.present?
          publishers = publishers.select { |p| p[:name].downcase.include?(query.downcase) }
        end
        if letter.present?
          publishers = publishers.select { |p| p[:name].start_with?(letter) }
        end
        render json: publishers
      end
    end
  end

  def letter_data
    letter = params[:letter]&.upcase
    @publishers = Book.where.not(publisher: [nil, ''])
                      .where("UPPER(publisher) LIKE ?", "#{letter}%")
                      .group(:publisher)
                      .count
                      .sort_by { |_, count| -count }
    render json: { publishers: @publishers.map { |name, count| { name: name, count: count } } }
  end

  def show
    @publisher_name = resolve_publisher_slug(params[:slug])
    unless @publisher_name
      render file: 'public/404.html', status: :not_found and return
    end
    @books = Book.where(publisher: @publisher_name).includes(:book_stores => :store)
    sort_col = params[:sort].presence_in(%w[name author publisher library year]) || 'name'
    sort_dir = params[:direction].presence_in(%w[asc desc]) || 'asc'
    @books = @books.order("#{sort_col} #{sort_dir}")
    @books = Kaminari.paginate_array(@books).page(params[:page]).per(20)
  end
end
