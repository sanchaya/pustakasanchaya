# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20260608174316) do

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",         limit: 255,                   null: false
    t.string   "name",          limit: 255
    t.string   "password_hash", limit: 255
    t.string   "role",          limit: 255, default: "admin"
    t.boolean  "active",                    default: true
    t.datetime "last_login"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree

  create_table "book_stores", force: :cascade do |t|
    t.integer  "book_id",      limit: 4,   null: false
    t.integer  "store_id",     limit: 4,   null: false
    t.string   "store_url",    limit: 255
    t.string   "price",        limit: 255
    t.string   "availability", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "book_stores", ["book_id", "store_id"], name: "index_book_stores_on_book_id_and_store_id", unique: true, using: :btree
  add_index "book_stores", ["store_id"], name: "index_book_stores_on_store_id", using: :btree

  create_table "books", force: :cascade do |t|
    t.string   "source_identifier", limit: 255,   null: false
    t.string   "name",              limit: 255
    t.string   "name_english",      limit: 255
    t.string   "author",            limit: 255
    t.string   "publisher",         limit: 255
    t.string   "categories",        limit: 255
    t.string   "library",           limit: 255
    t.string   "year",              limit: 255
    t.string   "book_link",         limit: 255
    t.string   "archive_url",       limit: 255
    t.text     "metadata",          limit: 65535
    t.string   "thumbnail",         limit: 255
    t.string   "language",          limit: 255
    t.string   "source",            limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "books", ["author"], name: "index_books_on_author", using: :btree
  add_index "books", ["library"], name: "index_books_on_library", using: :btree
  add_index "books", ["name"], name: "index_books_on_name", using: :btree
  add_index "books", ["publisher"], name: "index_books_on_publisher", using: :btree
  add_index "books", ["source_identifier"], name: "index_books_on_source_identifier", unique: true, using: :btree

  create_table "corrections", force: :cascade do |t|
    t.string   "correction_type",   limit: 255,   null: false
    t.string   "editor",            limit: 255
    t.string   "source_identifier", limit: 255
    t.string   "field",             limit: 255
    t.text     "old_value",         limit: 65535
    t.text     "new_value",         limit: 65535
    t.text     "source_ids",        limit: 65535
    t.string   "canonical_id",      limit: 255
    t.text     "description",       limit: 65535
    t.datetime "timestamp"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "corrections", ["correction_type"], name: "index_corrections_on_correction_type", using: :btree
  add_index "corrections", ["editor"], name: "index_corrections_on_editor", using: :btree
  add_index "corrections", ["source_identifier"], name: "index_corrections_on_source_identifier", using: :btree

  create_table "invites", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.string   "token",      limit: 255
    t.string   "role",       limit: 255
    t.boolean  "used",                   default: false
    t.datetime "used_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "stores", force: :cascade do |t|
    t.string   "name",       limit: 255,                null: false
    t.string   "url",        limit: 255
    t.string   "logo",       limit: 255
    t.boolean  "active",                 default: true, null: false
    t.integer  "position",   limit: 4,   default: 0,    null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "stores", ["active"], name: "index_stores_on_active", using: :btree
  add_index "stores", ["name"], name: "index_stores_on_name", unique: true, using: :btree

  add_foreign_key "book_stores", "books"
  add_foreign_key "book_stores", "stores"
end
