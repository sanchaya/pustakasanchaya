class BookStore < ActiveRecord::Base
  belongs_to :book
  belongs_to :store

  validates :book_id, uniqueness: { scope: :store_id }
end