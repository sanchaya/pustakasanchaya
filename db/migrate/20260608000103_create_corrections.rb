class CreateCorrections < ActiveRecord::Migration
  def change
    create_table :corrections do |t|
      t.string :correction_type, null: false
      t.string :editor
      t.string :source_identifier
      t.string :field
      t.text :old_value
      t.text :new_value
      t.text :source_ids
      t.string :canonical_id
      t.text :description
      t.datetime :timestamp
      t.timestamps null: false
    end

    add_index :corrections, :correction_type
    add_index :corrections, :editor
    add_index :corrections, :source_identifier
  end
end
