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

ActiveRecord::Schema.define(version: 20260626010000) do

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

  create_table "affiliations", force: :cascade do |t|
    t.integer  "person_id",        limit: 4
    t.string   "institution_name", limit: 255,   null: false
    t.string   "role",             limit: 255
    t.integer  "start_year",       limit: 4
    t.integer  "end_year",         limit: 4
    t.text     "notes",            limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "affiliations", ["person_id"], name: "index_affiliations_on_person_id", using: :btree

  create_table "awards", force: :cascade do |t|
    t.integer  "person_id",   limit: 4
    t.string   "name",        limit: 255,   null: false
    t.integer  "year",        limit: 4
    t.string   "institution", limit: 255
    t.text     "notes",       limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "awards", ["person_id"], name: "index_awards_on_person_id", using: :btree

  create_table "book_contributions", force: :cascade do |t|
    t.integer  "book_id",    limit: 4,              null: false
    t.integer  "person_id",  limit: 4,              null: false
    t.string   "role",       limit: 50,             null: false
    t.integer  "position",   limit: 4,  default: 0
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "book_contributions", ["book_id", "person_id", "role"], name: "idx_book_contributions_unique", unique: true, using: :btree
  add_index "book_contributions", ["book_id"], name: "index_book_contributions_on_book_id", using: :btree
  add_index "book_contributions", ["person_id"], name: "index_book_contributions_on_person_id", using: :btree

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
    t.string   "source_identifier",        limit: 255,                   null: false
    t.string   "name",                     limit: 255
    t.string   "name_english",             limit: 255
    t.string   "author",                   limit: 255
    t.string   "publisher",                limit: 255
    t.string   "categories",               limit: 255
    t.string   "library",                  limit: 255
    t.string   "year",                     limit: 255
    t.string   "book_link",                limit: 255
    t.string   "archive_url",              limit: 255
    t.text     "metadata",                 limit: 65535
    t.string   "thumbnail",                limit: 255
    t.string   "language",                 limit: 255
    t.string   "source",                   limit: 255
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "item_type",                limit: 255
    t.text     "merged_sources",           limit: 65535
    t.text     "thumbnail_failed_sources", limit: 65535
    t.string   "author_kannada",           limit: 255
    t.string   "author_latin",             limit: 255
    t.string   "author_2",                 limit: 255
    t.string   "author_3",                 limit: 255
    t.string   "publisher_kannada",        limit: 255
    t.string   "publisher_latin",          limit: 255
    t.string   "name_kannada",             limit: 255
    t.string   "name_latin",               limit: 255
    t.string   "author_role",              limit: 50
    t.string   "author_2_role",            limit: 50
    t.string   "author_3_role",            limit: 50
    t.boolean  "is_translation",                         default: false
    t.string   "translation_source_lang",  limit: 50
    t.string   "translation_dest_lang",    limit: 50,    default: "kn"
    t.string   "edition",                  limit: 100
    t.string   "isbn",                     limit: 20
    t.string   "oclc",                     limit: 50
    t.string   "dewey",                    limit: 20
    t.string   "loc_classification",       limit: 50
    t.integer  "pages",                    limit: 4
    t.string   "media_type",               limit: 50
    t.string   "genre",                    limit: 255
    t.string   "subject",                  limit: 255
    t.text     "summary",                  limit: 65535
    t.string   "series",                   limit: 255
    t.string   "original_title",           limit: 255
    t.string   "original_author",          limit: 255
    t.string   "translator",               limit: 255
    t.string   "illustrator",              limit: 255
    t.text     "awards",                   limit: 65535
    t.string   "wikipedia_url",            limit: 500
    t.string   "wikidata_id",              limit: 20
    t.string   "original_publisher",       limit: 255
    t.string   "original_year",            limit: 10
    t.string   "original_language",        limit: 50
    t.string   "place_of_publication",     limit: 255
    t.string   "printer_name",             limit: 255
    t.text     "printer_address",          limit: 65535
    t.string   "ol_key",                   limit: 255
    t.string   "author_slug",              limit: 255
    t.string   "publisher_slug",           limit: 255
  end

  add_index "books", ["author"], name: "index_books_on_author", using: :btree
  add_index "books", ["author_kannada"], name: "index_books_on_author_kannada", using: :btree
  add_index "books", ["author_latin"], name: "index_books_on_author_latin", using: :btree
  add_index "books", ["author_role"], name: "index_books_on_author_role", using: :btree
  add_index "books", ["author_slug"], name: "index_books_on_author_slug", using: :btree
  add_index "books", ["is_translation"], name: "index_books_on_is_translation", using: :btree
  add_index "books", ["item_type"], name: "index_books_on_item_type", using: :btree
  add_index "books", ["library"], name: "index_books_on_library", using: :btree
  add_index "books", ["name", "author"], name: "index_books_on_name_author", using: :btree
  add_index "books", ["name"], name: "index_books_on_name", using: :btree
  add_index "books", ["name_kannada"], name: "index_books_on_name_kannada", using: :btree
  add_index "books", ["ol_key"], name: "index_books_on_ol_key", using: :btree
  add_index "books", ["publisher"], name: "index_books_on_publisher", using: :btree
  add_index "books", ["publisher_kannada"], name: "index_books_on_publisher_kannada", using: :btree
  add_index "books", ["publisher_latin"], name: "index_books_on_publisher_latin", using: :btree
  add_index "books", ["publisher_slug"], name: "index_books_on_publisher_slug", using: :btree
  add_index "books", ["source_identifier"], name: "index_books_on_source_identifier", unique: true, using: :btree
  add_index "books", ["updated_at"], name: "index_books_on_updated_at", using: :btree
  add_index "books", ["year"], name: "index_books_on_year", using: :btree

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

  create_table "name_suggestions", force: :cascade do |t|
    t.string   "original_name",   limit: 255,                       null: false
    t.string   "suggested_name",  limit: 255,                       null: false
    t.string   "status",          limit: 20,    default: "pending"
    t.string   "suggester_name",  limit: 255
    t.text     "notes",           limit: 65535
    t.string   "reviewed_by",     limit: 255
    t.datetime "reviewed_at"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "suggested_latin", limit: 255
    t.string   "entity_type",     limit: 50,    default: "author"
    t.string   "entity_slug",     limit: 255
    t.string   "suggested_role",  limit: 50
    t.boolean  "is_translation"
    t.string   "source_lang",     limit: 50
    t.string   "dest_lang",       limit: 50
    t.string   "book_identifier", limit: 255
  end

  add_index "name_suggestions", ["book_identifier"], name: "index_name_suggestions_on_book_identifier", using: :btree
  add_index "name_suggestions", ["original_name"], name: "index_name_suggestions_on_original_name", using: :btree
  add_index "name_suggestions", ["status"], name: "index_name_suggestions_on_status", using: :btree

  create_table "name_variants", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.string   "name",       limit: 255, null: false
    t.string   "notes",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "name_variants", ["person_id"], name: "index_name_variants_on_person_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "name_kannada",        limit: 255
    t.string   "name_latin",          limit: 255
    t.text     "notes",               limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.date     "birth_date"
    t.date     "death_date"
    t.text     "biography",           limit: 65535
    t.string   "website_url",         limit: 255
    t.string   "wikipedia_url",       limit: 255
    t.string   "birthplace",          limit: 255
    t.string   "nationality",         limit: 100
    t.string   "occupation",          limit: 255
    t.string   "genre",               limit: 255
    t.text     "education",           limit: 65535
    t.string   "father_name",         limit: 255
    t.string   "father_name_kannada", limit: 255
    t.string   "mother_name",         limit: 255
    t.string   "mother_name_kannada", limit: 255
    t.string   "spouse_name",         limit: 255
    t.string   "spouse_name_kannada", limit: 255
    t.text     "children",            limit: 65535
    t.string   "period",              limit: 255
    t.string   "language",            limit: 255
    t.text     "notable_works",       limit: 65535
    t.string   "place_of_work",       limit: 255
    t.string   "death_place",         limit: 255
    t.string   "alma_mater",          limit: 255
    t.string   "image_url",           limit: 255
    t.string   "citizenship",         limit: 255
  end

  add_index "people", ["name"], name: "index_people_on_name", using: :btree
  add_index "people", ["name_kannada"], name: "index_people_on_name_kannada", using: :btree
  add_index "people", ["name_latin"], name: "index_people_on_name_latin", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 50,  null: false
    t.string   "description", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "roles", ["name"], name: "index_roles_on_name", unique: true, using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "key",        limit: 255,   null: false
    t.text     "value",      limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "settings", ["key"], name: "index_settings_on_key", unique: true, using: :btree

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
  add_foreign_key "name_variants", "people"
end
