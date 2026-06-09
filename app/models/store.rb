class Store < ActiveRecord::Base
  has_many :book_stores, dependent: :destroy
  has_many :books, through: :book_stores

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true, uniqueness: true
end