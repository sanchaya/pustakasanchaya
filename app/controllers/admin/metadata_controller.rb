class Admin::MetadataController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def authors
    @authors = Author.all_with_counts
    @search_query = params[:search] || ''
    
    if @search_query.present?
      @authors = @authors.select { |name, _count| name.downcase.include?(@search_query.downcase) }
    end
    
    @authors = Kaminari.paginate_array(@authors.map { |name, count| { name: name, count: count } }).page(params[:page]).per(30)
  end

  def publishers
    @publishers = Publisher.all_with_counts
    @search_query = params[:search] || ''
    
    if @search_query.present?
      @publishers = @publishers.select { |name, _count| name.downcase.include?(@search_query.downcase) }
    end
    
    @publishers = Kaminari.paginate_array(@publishers.map { |name, count| { name: name, count: count } }).page(params[:page]).per(30)
  end

  def find_similar_authors
    author_name = params[:author] || ''
    return render json: { similar: [] } if author_name.blank?
    
    similar = Author.find_similar(author_name)
    
    render json: {
      search_term: author_name,
      similar: similar,
      count: similar.length
    }
  end

  def find_similar_publishers
    publisher_name = params[:publisher] || ''
    return render json: { similar: [] } if publisher_name.blank?
    
    similar = Publisher.find_similar(publisher_name)
    
    render json: {
      search_term: publisher_name,
      similar: similar,
      count: similar.length
    }
  end

  def merge_authors
    old_author = params[:old_author] || ''
    new_author = params[:new_author] || ''
    
    unless old_author.present? && new_author.present?
      return render json: { success: false, error: 'Both authors must be specified' }
    end
    
    result = Author.merge(old_author, new_author, current_admin.email)
    
    render json: result
  end

  def merge_publishers
    old_publisher = params[:old_publisher] || ''
    new_publisher = params[:new_publisher] || ''
    
    unless old_publisher.present? && new_publisher.present?
      return render json: { success: false, error: 'Both publishers must be specified' }
    end
    
    result = Publisher.merge(old_publisher, new_publisher, current_admin.email)
    
    render json: result
  end

  def rename_author
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Author.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  def rename_publisher
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Publisher.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  def categories
    @categories = Category.all_with_counts
    @search_query = params[:search] || ''
    
    if @search_query.present?
      @categories = @categories.select { |name, _count| name.downcase.include?(@search_query.downcase) }
    end
    
    @categories = Kaminari.paginate_array(@categories.map { |name, count| { name: name, count: count } }).page(params[:page]).per(30)
  end

  def find_similar_categories
    category_name = params[:category] || ''
    return render json: { similar: [] } if category_name.blank?
    
    similar = Category.find_similar(category_name)
    
    render json: {
      search_term: category_name,
      similar: similar,
      count: similar.length
    }
  end

  def merge_categories
    old_category = params[:old_category] || ''
    new_category = params[:new_category] || ''
    
    unless old_category.present? && new_category.present?
      return render json: { success: false, error: 'Both categories must be specified' }
    end
    
    result = Category.merge(old_category, new_category, current_admin.email)
    
    render json: result
  end

  def rename_category
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Category.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  def libraries
    @libraries = Library.all_with_counts
    @search_query = params[:search] || ''
    
    if @search_query.present?
      @libraries = @libraries.select { |name, _count| name.downcase.include?(@search_query.downcase) }
    end
    
    @libraries = Kaminari.paginate_array(@libraries.map { |name, count| { name: name, count: count } }).page(params[:page]).per(30)
  end

  def find_similar_libraries
    library_name = params[:library] || ''
    return render json: { similar: [] } if library_name.blank?
    
    similar = Library.find_similar(library_name)
    
    render json: {
      search_term: library_name,
      similar: similar,
      count: similar.length
    }
  end

  def merge_libraries
    old_library = params[:old_library] || ''
    new_library = params[:new_library] || ''
    
    unless old_library.present? && new_library.present?
      return render json: { success: false, error: 'Both libraries must be specified' }
    end
    
    result = Library.merge(old_library, new_library, current_admin.email)
    
    render json: result
  end

  def rename_library
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Library.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  private

  def authorize_admin!
    unless session[:admin_id]
      redirect_to admin_login_path, alert: 'Please login first'
    end
  end

  def current_admin
    @current_admin ||= Admin.find(session[:admin_id]) if session[:admin_id]
  end

  helper_method :current_admin
end
