class Invite < ActiveRecord::Base
  scope :unused, -> { where(used: false) }
end
