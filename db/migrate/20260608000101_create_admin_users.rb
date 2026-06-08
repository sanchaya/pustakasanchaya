class CreateAdminUsers < ActiveRecord::Migration
  def change
    create_table :admin_users do |t|
      t.string :email, null: false
      t.string :name
      t.string :password_hash
      t.string :role, default: 'admin'
      t.boolean :active, default: true
      t.datetime :last_login
      t.timestamps null: false
    end

    add_index :admin_users, :email, unique: true
  end
end
