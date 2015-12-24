class BooksController < ApplicationController

  def index
    begin
      if params && params[:search] && !params[:search].blank?
        books = JSON.parse(Book.search(params[:search]))
        @books = Kaminari.paginate_array(books).page(params[:page]).per(8) 
      else
        @wiki_book = JSON.parse(Book.wiki_search)
      end
    rescue
      @books = {}
    end
  end

  def wiki_info
    book_name = params['book']
    Book.capture_wiki_user(book_name,'false')
    render nothing: true
  end

  def wiki_user_info
    user_name = params[:user_name]
    book_name = params[:book_name]
    Book.capture_wiki_user(book_name,'true',user_name)
    flash[:notice] = "Thanks for creating Wiki article"
    redirect_to root_path
  end

end
