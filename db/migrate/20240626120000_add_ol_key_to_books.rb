class AddOlKeyToBooks < ActiveRecord::Migration
  def change
    add_column :books, :ol_key, :string
    add_index :books, :ol_key
  end
end