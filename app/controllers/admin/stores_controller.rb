class Admin::StoresController < ApplicationController
  layout 'admin'
  before_action :authorize_admin!

  def index
    @stores = Store.ordered
    @total_stores = Store.count
    @active_stores = Store.active.count
  end

  def new
    @store = Store.new
  end

  def create
    @store = Store.new(store_params)
    if @store.save
      redirect_to admin_stores_path, notice: 'Store created successfully'
    else
      flash[:alert] = "Error creating store: #{@store.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def edit
    @store = Store.find(params[:id])
  end

  def update
    @store = Store.find(params[:id])
    if @store.update(store_params)
      redirect_to admin_stores_path, notice: 'Store updated successfully'
    else
      flash[:alert] = "Error updating store: #{@store.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    @store = Store.find(params[:id])
    if @store.destroy
      redirect_to admin_stores_path, notice: 'Store deleted successfully'
    else
      flash[:alert] = "Error deleting store: #{@store.errors.full_messages.join(', ')}"
      redirect_to admin_stores_path
    end
  end

  def toggle_active
    @store = Store.find(params[:id])
    if @store.update(active: !@store.active)
      redirect_to admin_stores_path, notice: "Store successfuly #{@store.active ? 'activated' : 'deactivated'}"
    else
      flash[:alert] = "Error toggling store status: #{@store.errors.full_messages.join(', ')}"
      redirect_to admin_stores_path
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

  def store_params
    params.require(:store).permit(:name, :url, :logo, :active, :position)
  end
end