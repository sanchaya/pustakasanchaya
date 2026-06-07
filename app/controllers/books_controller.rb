class BooksController < ApplicationController

  def index
    begin
      if params && params[:search] && !params[:search].blank?
        # Search remote API
        remote_books = begin
          JSON.parse(Book.search(params[:search]))
        rescue StandardError
          []
        end
        # Search local caches (IA imports + Ankita Pustaka)
        local_books = begin
          Book.search_all_cached(params[:search])
        rescue StandardError
          []
        end
        # Merge and deduplicate
        all_books = (remote_books + local_books).uniq { |b| b['source_identifier'] || b['name'] }
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

end
