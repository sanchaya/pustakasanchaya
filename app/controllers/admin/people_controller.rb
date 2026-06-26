class Admin::PeopleController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @role = params[:role]
    scope = Person.all
    
    if @role.present?
      scope = scope.where("LOWER(occupation) = ?", @role.downcase)
    end
    
    @people = scope.order(:name).page(params[:page]).per(30)
    
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
    
    affected = Person.where(name: old_name)
    count = affected.count
    affected.update_all(name: new_name)
    
    render json: { success: true, renamed_from: old_name, renamed_to: new_name, affected_count: count }
  end

  def merge
    old_id = params[:old_id]
    new_id = params[:new_id]
    
    unless old_id.present? && new_id.present?
      return render json: { success: false, error: 'Both IDs must be specified' }
    end
    
    old_person = Person.find_by(id: old_id)
    new_person = Person.find_by(id: new_id)
    
    unless old_person && new_person
      return render json: { success: false, error: 'One or both people not found' }
    end
    
    # Update books with old author name to new author name
    Book.where(author: old_person.name).update_all(author: new_person.name)
    Book.where(translator: old_person.name).update_all(translator: new_person.name)
    
    old_person.destroy
    
    render json: { success: true, merged_from: old_person.name, merged_to: new_person.name }
  end

  def merge_multiple
    source_ids = params[:source_ids] || []
    target_id = params[:target_id]
    
    unless source_ids.present? && target_id.present?
      return render json: { success: false, error: 'Source IDs and target ID must be specified' }
    end
    
    target_person = Person.find_by(id: target_id)
    unless target_person
      return render json: { success: false, error: 'Target person not found' }
    end
    
    Person.where(id: source_ids).each do |source|
      Book.where(author: source.name).update_all(author: target_person.name)
      Book.where(translator: source.name).update_all(translator: target_person.name)
      source.destroy
    end
    
    render json: { success: true, merged_count: source_ids.length }
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

  def admin_person_params
    params.require(:person).permit(:name, :name_kannada, :name_latin, :bio, :birthplace, :nationality, :occupation, :genre, :education)
  end
end