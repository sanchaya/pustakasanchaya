class Admin::CorrectionsController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    corrections_data = Correction.all
    @edits = corrections_data['edits'] || []
    @edits = Kaminari.paginate_array(@edits.reverse).page(params[:page]).per(20)
  end

  def audit_log
    @audit_log = Correction.audit_log(500)
    @audit_log = Kaminari.paginate_array(@audit_log).page(params[:page]).per(50)
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
