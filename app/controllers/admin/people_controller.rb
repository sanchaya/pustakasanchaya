class Admin::PeopleController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!
  skip_before_action :verify_authenticity_token

def index
    @role = params[:role]
    @search_query = params[:search] || ''
    scope = Person.all

    if @role.present?
      scope = scope.where("LOWER(occupation) = ?", @role.downcase)
    end

    if @search_query.present?
      q = @search_query
      scope = scope.where("name LIKE ? OR name_kannada LIKE ? OR name_latin LIKE ?", "%#{q}%", "%#{q}%", "%#{q}%")
    end

    @people = Kaminari.paginate_array(scope.order(:name)).page(params[:page]).per(30)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @people }
    end
  end

  def show
    @person = Person.find(params[:id])
  end

  def new
    @person = Person.new
  end

  def create
    @person = Person.new(admin_person_params)
    if @person.save
      redirect_to admin_people_path, notice: 'Person created.'
    else
      render :new
    end
  end

  def edit
    @person = Person.find(params[:id])
  end

  def update
    @person = Person.find(params[:id])
    if @person.update(admin_person_params)
      redirect_to admin_people_path, notice: 'Person updated.'
    else
      render :edit
    end
  end

  def destroy
    @person = Person.find(params[:id])
    @person.destroy
    redirect_to admin_people_path, notice: 'Person deleted.'
  end

  def find_similar
    name = params[:name] || ''
    return render json: { similar: [] } if name.blank?
    
    similar = Person.where("name ILIKE ? OR name_kannada ILIKE ?", "%#{name}%", "%#{name}%")
                    .where.not(id: params[:exclude_id])
                    .limit(10)
    
    render json: { similar: similar.map { |p| { id: p.id, name: p.name, name_kannada: p.name_kannada, occupation: p.occupation } } }
  end

  def search_books
    person = Person.find(params[:id])
    books = Book.where(author: person.name).or(Book.where(translator: person.name)).limit(20)
    render json: { books: books.map { |b| { id: b.id, name: b.name, author: b.author } } }
  end

def rename
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    affected = Book.where(author: old_name)
    count = affected.count
    affected.update_all(author: new_name, author_slug: SlugHelper.slug_for(new_name))
    Book.bump_search_cache
    Book.invalidate_slug_cache! if count > 0
    Person.where(name: old_name).update_all(name: new_name)
    render json: { success: true, renamed_from: old_name, renamed_to: new_name, affected_count: count }
  end

  def merge
    old_name = params[:old_name] || ''
    new_name = params[:new_name] || ''
    unless old_name.present? && new_name.present?
      return render json: { success: false, error: 'Both names must be specified' }
    end
    affected = Book.where(author: old_name)
    count = affected.count
    affected.update_all(author: new_name, author_slug: SlugHelper.slug_for(new_name))
    Book.bump_search_cache
    Book.invalidate_slug_cache! if count > 0
    Person.where(name: old_name).destroy_all
    render json: { success: true, merged_from: old_name, merged_to: new_name, affected_count: count }
  end

def merge_multiple
    source_ids = params[:source_ids] || []
    target_name = params[:target_name] || ''

    unless source_ids.present? && target_name.present?
      return render json: { success: false, error: 'Source IDs and target name must be specified' }
    end

    total = 0
    Person.where(id: source_ids).each do |source|
      next if source.name == target_name
      count = Book.where(author: source.name).update_all(author: target_name, author_slug: SlugHelper.slug_for(target_name))
      total += count
      source.destroy
    end
    Book.bump_search_cache
    Book.invalidate_slug_cache! if total > 0

    render json: { success: true, merged_count: total }
  end

  def add_contribution
    @person = Person.find(params[:id])
    # Contribution logic would go here
    render json: { success: true, message: 'Contribution added' }
  end

  def update_contribution
    render json: { success: true, message: 'Contribution updated' }
  end

  def remove_contribution
    render json: { success: true, message: 'Contribution removed' }
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

  def admin_person_params
    params.require(:person).permit(:name, :name_kannada, :name_latin, :bio, :birthplace, :nationality, :occupation, :genre, :education)
  end
end