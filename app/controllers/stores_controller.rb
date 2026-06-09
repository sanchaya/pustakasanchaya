class StoresController < ApplicationController
  def index
    @stores = Store.active.ordered
  end
end