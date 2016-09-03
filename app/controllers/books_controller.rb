class BooksController < ApplicationController

  def index
    begin
      if params && params[:search] && !params[:search].blank?
        books = JSON.parse(Book.search(params[:search]))
        @books = Kaminari.paginate_array(books).page(params[:page]).per(8)
      else
        @wiki_book = JSON.parse(Book.wiki_search)
        puts @wiki_book['other_metadata'].inspect
        puts @wiki_book['other_metadata']['wikimedia_url'].inspect
      end
    rescue
      @books = {}
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

  # Static info for wiki article creation
  def edit_wikipedia
  end

end
