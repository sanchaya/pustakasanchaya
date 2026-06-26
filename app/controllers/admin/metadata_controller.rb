class Admin::MetadataController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def parse_json_body
    if request.content_type == 'application/json'
      body = request.body.read
      if body.present?
        json_params = JSON.parse(body)
        params.merge!(json_params)
      end
    end
  end

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
    
    Rails.logger.info "[merge_publishers] old_publisher=#{old_publisher.inspect}, new_publisher=#{new_publisher.inspect}, current_admin=#{current_admin.inspect}"
    
    unless old_publisher.present? && new_publisher.present?
      return render json: { success: false, error: 'Both publishers must be specified' }
    end
    
    result = Publisher.merge(old_publisher, new_publisher, current_admin.email)
    Rails.logger.info "[merge_publishers] result=#{result.inspect}"
    
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
    
    Rails.logger.info "[rename_publisher] old_name=#{old_name.inspect}, new_name=#{new_name.inspect}, current_admin=#{current_admin.inspect}"
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Publisher.rename(old_name, new_name, current_admin.email)
    Rails.logger.info "[rename_publisher] result=#{result.inspect}"
    
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
    parse_json_body
    old_category = params[:old_category] || ''
    new_category = params[:new_category] || ''
    
    unless old_category.present? && new_category.present?
      return render json: { success: false, error: 'Both categories must be specified' }
    end
    
    result = Category.merge(old_category, new_category, current_admin.email)
    
    render json: result
  end

  def rename_category
    parse_json_body
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Category.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  def merge_multiple_authors
    parse_json_body
    source_names = params[:source_names] || []
    target_name = params[:target_name] || ''
    result = Author.merge_multiple(source_names, target_name, current_admin.email)
    render json: result
  end

  def merge_multiple_publishers
    parse_json_body
    source_names = params[:source_names] || []
    target_name = params[:target_name] || ''
    result = Publisher.merge_multiple(source_names, target_name, current_admin.email)
    render json: result
  end

  def merge_multiple_categories
    parse_json_body
    source_names = params[:source_names] || []
    target_name = params[:target_name] || ''
    result = Category.merge_multiple(source_names, target_name, current_admin.email)
    render json: result
  end

  def merge_multiple_libraries
    parse_json_body
    source_names = params[:source_names] || []
    target_name = params[:target_name] || ''
    result = Library.merge_multiple(source_names, target_name, current_admin.email)
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
    parse_json_body
    old_library = params[:old_library] || ''
    new_library = params[:new_library] || ''
    
    unless old_library.present? && new_library.present?
      return render json: { success: false, error: 'Both libraries must be specified' }
    end
    
    result = Library.merge(old_library, new_library, current_admin.email)
    
    render json: result
  end

  def rename_library
    parse_json_body
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    
    result = Library.rename(old_name, new_name, current_admin.email)
    
    render json: result
  end

  def suggested_merges
    @dismissed = session[:dismissed_suggestions] || []
    @author_suggestions = compute_author_suggestions.reject { |s| @dismissed.include?(s[:id]) }
    @publisher_suggestions = compute_publisher_suggestions.reject { |s| @dismissed.include?(s[:id]) }
    @book_suggestions = compute_book_suggestions.reject { |s| @dismissed.include?(s[:id]) }
  end

  def apply_suggestion
    parse_json_body
    type = params[:type]
    source = params[:source]
    target = params[:target]

    result = case type
    when 'author'
      Author.merge(source, target, current_admin.email)
    when 'publisher'
      Publisher.merge(source, target, current_admin.email)
    when 'book'
      apply_book_merge(source, target)
    else
      { success: false, error: "Unknown type: #{type}" }
    end

    render json: result
  end

  def dismiss_suggestion
    parse_json_body
    session[:dismissed_suggestions] ||= []
    id = "#{params[:type]}:#{params[:source]}:#{params[:target]}"
    session[:dismissed_suggestions] << id unless session[:dismissed_suggestions].include?(id)
    render json: { success: true }
  end

  private

  def compute_author_suggestions
    cache_key = 'merge_suggestions/authors/v3'
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      suggestions = []
      counts = Book.author_counts

      normalized = {}
      counts.each do |name, _|
        norm = normalize_name(name)
        normalized[norm] ||= { names: [], max_count: 0, max_name: nil }
        normalized[norm][:names] << name
        if (counts[name] || 0) > normalized[norm][:max_count]
          normalized[norm][:max_count] = (counts[name] || 0)
          normalized[norm][:max_name] = name
        end
      end

      normalized.each do |_, group|
        next if group[:names].length < 2
        target = group[:max_name]
        group[:names].each do |source|
          next if source == target
          suggestions << build_suggestion('author', source, target, counts, 'normalized')
        end
      end

      suggestions.sort_by { |s| -s[:target_count] }.first(100)
    end
  end

  def compute_publisher_suggestions
    cache_key = 'merge_suggestions/publishers/v2'
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      suggestions = []
      counts = Book.publisher_counts

      names = counts.keys
      normalized = {}
      names.each do |name|
        norm = normalize_name(name)
        normalized[norm] ||= []
        normalized[norm] << name
      end

      normalized.each do |_norm, group|
        next if group.length < 2
        target = group.max_by { |n| counts[n] || 0 }
        group.each do |source|
          next if source == target
          suggestions << build_suggestion('publisher', source, target, counts, 'normalized')
        end
      end

      suggestions.sort_by { |s| -s[:target_count] }.first(100)
    end
  end

  def compute_book_suggestions
    cache_key = 'merge_suggestions/books/v2'
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      suggestions = []

      Book.where.not(name: [nil, ''])
          .where.not(author: [nil, ''])
          .group(:name, :author)
          .having('count(*) > 1')
          .order('count_all DESC')
          .limit(100)
          .count
          .each do |(name, author), count|
        books = Book.where(name: name, author: author).limit(5)
        next if books.length < 2

        target = books.first
        books.drop(1).each do |source|
          suggestions << {
            id: "book:#{source.source_identifier}:#{target.source_identifier}",
            type: 'book',
            source: source.source_identifier,
            source_title: source.name,
            source_author: source.author,
            source_library: source.library,
            target: target.source_identifier,
            target_title: target.name,
            target_author: target.author,
            target_library: target.library,
            match_type: 'exact',
            confidence: 1.0
          }
        end
      end

      suggestions.first(100)
    end
  end

  def build_suggestion(type, source, target, counts, match_type)
    {
      id: "#{type}:#{source}:#{target}",
      type: type,
      source: source,
      source_count: counts[source] || 0,
      target: target,
      target_count: counts[target] || 0,
      match_type: match_type,
      confidence: match_type == 'normalized' ? 0.95 : 0.7
    }
  end

  def normalize_name(name)
    name.strip.downcase.gsub(/[[:punct:]]/, ' ').gsub(/\s+/, ' ').strip
  end

  def apply_book_merge(source_id, target_id)
    source = Book.find_by(source_identifier: source_id)
    target = Book.find_by(source_identifier: target_id)

    unless source && target
      return { success: false, error: 'One or both books not found' }
    end

    Correction.record_merge(
      [source_id],
      target_id,
      { 'source_identifier' => source_id, 'name' => source.name, 'author' => source.author },
      current_admin.email,
      "Merged book '#{source.name}' (#{source_id}) into '#{target.name}' (#{target_id})"
    )
    source.destroy
    { success: true, message: "Merged into #{target.name}" }
  end

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
