class AdminUser < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  def super_admin?
    role == 'super_admin'
  end
end
