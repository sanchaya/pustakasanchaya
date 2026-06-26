class AddSlugColumnsToBooks < ActiveRecord::Migration
  def up
    add_column :books, :author_slug, :string, limit: 255
    add_column :books, :publisher_slug, :string, limit: 255
    add_index :books, :author_slug
    add_index :books, :publisher_slug
  end

  def down
    remove_index :books, :publisher_slug
    remove_index :books, :author_slug
    remove_column :books, :publisher_slug
    remove_column :books, :author_slug
  end
end
