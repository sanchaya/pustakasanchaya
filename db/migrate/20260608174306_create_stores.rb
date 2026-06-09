class CreateStores < ActiveRecord::Migration
  def change
    create_table :stores do |t|
      t.string :name, null: false
      t.string :url
      t.string :logo
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0, null: false
      t.timestamps null: false
    end
    add_index :stores, :name, unique: true
    add_index :stores, :active
  end
end
