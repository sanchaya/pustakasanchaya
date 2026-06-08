class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :source_identifier, null: false
      t.string :name
      t.string :name_english
      t.string :author
      t.string :publisher
      t.string :categories
      t.string :library
      t.string :year
      t.string :book_link
      t.string :archive_url
      t.text :metadata
      t.string :thumbnail
      t.string :language
      t.string :source
      t.timestamps null: false
    end

    add_index :books, :source_identifier, unique: true
    add_index :books, :author
    add_index :books, :publisher
    add_index :books, :library
    add_index :books, :name
  end
end
