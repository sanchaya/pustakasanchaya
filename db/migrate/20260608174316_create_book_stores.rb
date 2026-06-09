class CreateBookStores < ActiveRecord::Migration
  def change
    create_table :book_stores do |t|
      t.references :book, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.string :store_url
      t.string :price
      t.string :availability
      t.timestamps null: false
    end
    add_index :book_stores, [:book_id, :store_id], unique: true
    add_index :book_stores, :store_id
  end
end
