class BooksController < ApplicationController

  def index
    begin
      if params && params[:search] && !params[:search].blank?
        original_term = params[:search]
        # URL decoding corruption: U+0CBF (kn i  ಿ) sometimes gets corrupted to U+0CC7 (ೇ) during URL decoding.
        # Try both the original term and the corruption-fixed variant, merging results.
        fixed_term = params[:search].gsub('ೇ', 'ಿ')
        terms = [original_term, fixed_term].uniq

        all_books = terms.flat_map { |term| search_books(term) }
                        .uniq { |b| b['source_identifier'] || b['name'] }

        # Sort results
        sort_col = params[:sort].presence_in(%w[name author publisher library year]) || 'name'
        sort_dir = params[:direction].presence_in(%w[asc desc]) || 'asc'
        all_books = all_books.sort_by { |b| (b[sort_col] || '').downcase }
        all_books.reverse! if sort_dir == 'desc'

        @books = Kaminari.paginate_array(all_books).page(params[:page]).per(8)
      end
    rescue StandardError
      @books = Kaminari.paginate_array([]).page(params[:page]).per(8)
      flash.now[:alert] = 'Search service is temporarily unavailable. Please try again later.' if params[:search].present?
    end
    respond_to do |format|
      format.html
      format.js { render 'books/load_more' }
    end
  end

  # When users clicks on wiki signup, it captures only that user trying to signup, and on which article.
  def wiki_info
    book_name = params['book']
    Book.capture_wiki_user(book_name,'false')
    render nothing: true
  end

  # Method which captures user's account and article info
  def wiki_user_info
    user_name = session[:wiki_user_id]
    book_name = params[:book_name]
    book_id  = params[:book_id]
    library = params[:library]
    Book.capture_wiki_user(book_name,'true',user_name,book_id,library)
    flash[:notice] = "Thanks for creating Wiki article"
    redirect_to root_path
  end

  def capture_user_name
    session[:wiki_user_id] = params['user_name']
    render nothing: true
  end

  def fetch_thumbnail
    identifier = params[:identifier]
    return render json: { url: nil } unless identifier.present?
    
    thumb_url = "https://archive.org/services/img/#{identifier}"
    begin
      uri = URI.parse(thumb_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = 3
      head = http.request_head(uri.path)
      if head.code == '200'
        render json: { url: thumb_url }
        return
      end
    rescue
    end
    render json: { url: nil }
  end

  def debug_search
    original = (params[:q] || 'ಅಪರಂಜಿ')
    search_term = original.gsub('ೇ', 'ಿ')
    terms = [original, search_term].uniq

    count = terms.sum { |t| Book.where('LOWER(publisher) LIKE ?', "%#{t.downcase}%").count }
    count2 = terms.sum { |t| Book.where('LOWER(name) LIKE ? OR LOWER(author) LIKE ? OR LOWER(publisher) LIKE ? OR LOWER(library) LIKE ?', "%#{t.downcase}%", "%#{t.downcase}%", "%#{t.downcase}%", "%#{t.downcase}%").count }
    render json: {
      original_term: original,
      search_term: search_term,
      publisher_only: count,
      all_fields: count2
    }
  end

  def wiki
    begin
      @wiki_book = JSON.parse(Book.wiki_search)
    rescue StandardError
      @wiki_book = nil
      flash.now[:alert] = 'Wiki service is temporarily unavailable.'
    end
  end

  # Static info for wiki article creation
  def edit_wikipedia
  end

  private

  def search_books(search_term)
    remote_books = begin
      books = Book.search(search_term).to_a
      books.map do |b|
        h = b.attributes.with_indifferent_access
        h['book_link'] = h['book_link']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h['archive_url'] = h['archive_url']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h['metadata'] = h['metadata']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h
      end
    rescue StandardError
      []
    end

    local_books = begin
      Book.search_all_cached(search_term).map do |b|
        h = b.attributes.with_indifferent_access
        h['book_link'] = h['book_link']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h['archive_url'] = h['archive_url']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h['metadata'] = h['metadata']&.gsub('oudl_osmania_ac_in', 'oudl.osmania.ac.in')
        h
      end
    rescue StandardError
      []
    end

    local_by_id = {}
    local_books.each do |b|
      key = b['source_identifier'] || b['name']
      local_by_id[key] = b
    end

    (remote_books + local_books).uniq { |b| b['source_identifier'] || b['name'] }.map do |book|
      key = book['source_identifier'] || book['name']
      if local_by_id[key]
        local_book = local_by_id[key].dup
        book.each do |k, v|
          local_book[k] = v if local_book[k].blank? && v.present?
        end
        local_book
      else
        book
      end
    end
  end

end
