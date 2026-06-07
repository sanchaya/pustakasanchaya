class Admin::DashboardController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @admin = current_admin
    
    # Load statistics
    stats_file = Rails.root.join('db', 'stats.json')
    @stats = JSON.parse(File.read(stats_file)) if File.exist?(stats_file)

    # Load corrections count
    corrections_file = Rails.root.join('db', 'corrections.json')
    @corrections = JSON.parse(File.read(corrections_file)) if File.exist?(corrections_file)
    @corrections_count = @corrections ? @corrections['edits'].length : 0

    # Get recent edits
    @recent_edits = if @corrections
                      @corrections['edits'].reverse.first(10)
                    else
                      []
                    end
  end

  def editors
    authorize_super_admin!
    @admins = Admin.all
    @pending_invites = Admin.pending_invites
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
