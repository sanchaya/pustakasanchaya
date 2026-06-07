class Admin::DashboardController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @admin = current_admin
    
    # Load statistics
    stats_file = Rails.root.join('db', 'stats.json')
    @stats = JSON.parse(File.read(stats_file)) if File.exist?(stats_file)
    @stats ||= {
      'total_books' => 0,
      'total_authors' => 0,
      'total_publishers' => 0,
      'libraries' => {}
    }

    # Load corrections count
    corrections_file = Rails.root.join('db', 'corrections.json')
    @corrections = JSON.parse(File.read(corrections_file)) if File.exist?(corrections_file)
    @corrections ||= { 'edits' => [], 'merges' => [] }
    @corrections_count = @corrections['edits'].length

    # Get recent edits
    @recent_edits = @corrections['edits'].reverse.first(10)
  end

  def editors
    authorize_super_admin!
    @admins = Admin.all
    @pending_invites = Admin.pending_invites
  end

  def profile
    @admin = current_admin
  end

  def update_profile
    @admin = current_admin
    
    if params[:current_password].blank? && params[:new_password].blank?
      # Just update profile info
      if @admin.update_profile(params[:name], params[:email])
        redirect_to admin_dashboard_path, notice: 'Profile updated successfully'
      else
        redirect_to admin_profile_path, alert: 'Error updating profile'
      end
    else
      # Update password
      if params[:current_password].blank?
        redirect_to admin_profile_path, alert: 'Current password is required to change password'
        return
      end

      if params[:new_password].blank? || params[:new_password_confirm].blank?
        redirect_to admin_profile_path, alert: 'New password cannot be blank'
        return
      end

      if params[:new_password] != params[:new_password_confirm]
        redirect_to admin_profile_path, alert: 'Passwords do not match'
        return
      end

      if params[:new_password].length < 8
        redirect_to admin_profile_path, alert: 'Password must be at least 8 characters'
        return
      end

      # Verify current password
      authenticated = Admin.authenticate(@admin.email, params[:current_password])
      unless authenticated
        redirect_to admin_profile_path, alert: 'Current password is incorrect'
        return
      end

      # Update password
      if @admin.update_password(params[:new_password])
        redirect_to admin_dashboard_path, notice: 'Password changed successfully'
      else
        redirect_to admin_profile_path, alert: 'Error changing password'
      end
    end
  end

  private

  def authorize_admin!
    unless session[:admin_id]
      redirect_to admin_login_path, alert: 'Please login first'
    end
  end

  def authorize_super_admin!
    admin = Admin.find(session[:admin_id])
    unless admin && admin.super_admin?
      redirect_to admin_dashboard_path, alert: 'Unauthorized'
    end
  end

  def current_admin
    @current_admin ||= Admin.find(session[:admin_id]) if session[:admin_id]
  end

  helper_method :current_admin
end
