class Person < ActiveRecord::Base
  # Basic model for people records
  validates :name, presence: true

  # Optional extra attributes (birthplace, nationality, etc.) are added via migrations
end