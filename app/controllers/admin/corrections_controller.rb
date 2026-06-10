class Admin::CorrectionsController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @edits = Correction.edits.order(timestamp: :desc).page(params[:page])
  end

  def audit_log
    @audit_log = Correction.audit_log(500)
    @audit_log = Kaminari.paginate_array(@audit_log).page(params[:page]).per(50)
  end

  def destroy
    edit_id = params[:edit_id]
    
    begin
      correction = Correction.find_by(id: edit_id)
      
      if correction.nil?
        return render json: { success: false, error: 'Edit not found' }, status: 404
      end
      
      # Undo the edit by reverting to old value
      if correction.source_identifier.present?
        book = Book.find_by(source_identifier: correction.source_identifier)
        
        if book
          field = correction.field
          old_value = correction.old_value
          
          # Revert the field to its old value
          book.update(field.to_sym => old_value)
          
          # Log the undo action
          Correction.create(
            correction_type: 'edit',
            editor: current_admin&.email || 'system',
            source_identifier: correction.source_identifier,
            field: field,
            old_value: correction.new_value,
            new_value: old_value,
            description: "UNDO: Reverted #{field} from '#{correction.new_value}' back to '#{old_value}'",
            timestamp: Time.now
          )
          
          # Remove the original edit
          correction.destroy
          
          render json: { success: true, message: 'Edit undone successfully' }
        else
          render json: { success: false, error: 'Book not found' }, status: 404
        end
      else
        render json: { success: false, error: 'Cannot undo - source identifier missing' }, status: 400
      end
    rescue => e
      render json: { success: false, error: e.message }, status: 500
    end
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
