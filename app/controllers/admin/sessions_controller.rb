class Admin::SessionsController < ApplicationController
  layout 'admin'
  skip_before_action :verify_authenticity_token, only: [:logout]

  def login
    if request.post?
      admin = Admin.authenticate(params[:email], params[:password])
      if admin
        session[:admin_id] = admin.id
        session[:admin_email] = admin.email
        session[:admin_role] = admin.role
        redirect_to admin_dashboard_path, notice: "Welcome, #{admin.name}!"
      else
        flash.now[:alert] = 'Invalid email or password'
      end
    end
  end

  def logout
    session.clear
    redirect_to admin_login_path, notice: 'Logged out successfully'
  end

  def invite
    authorize_super_admin!
    
    if request.post?
      result = Admin.create_invite(params[:email], params[:role] || 'editor')
      if result[:success]
        invite_url = admin_accept_invite_url(token: result[:token])
        flash.now[:success] = "Invite created! Share this link: #{invite_url}"
        @invite = result[:invite]
      else
        flash.now[:alert] = result[:error]
      end
    end

    @pending_invites = Admin.pending_invites
  end

  def accept_invite
    token = params[:token]
    invite = Admin.find_invite(token)
    
    unless invite
      flash[:alert] = 'Invalid or expired invite'
      redirect_to admin_login_path
      return
    end

    if request.post?
      result = Admin.accept_invite(token, params[:name], params[:password])
      if result[:success]
        flash[:success] = 'Account created successfully! Please login.'
        redirect_to admin_login_path
      else
        flash.now[:alert] = result[:error]
      end
    else
      @invite = invite
    end
  end

  private

  def authorize_super_admin!
    unless session[:admin_id] && (admin = Admin.find(session[:admin_id])) && admin.super_admin?
      flash[:alert] = 'Unauthorized'
      redirect_to admin_login_path
    end
  end
end
