class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :email
      t.string :token
      t.string :role
      t.boolean :used, default: false
      t.datetime :used_at
      t.timestamps null: false
    end
  end
end
