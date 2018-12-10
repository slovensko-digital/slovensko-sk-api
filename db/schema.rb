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

ActiveRecord::Schema.define(version: 2018_12_10_164801) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "form_template_related_documents", force: :cascade do |t|
    t.bigint "form_template_id", null: false
    t.string "data", null: false
    t.string "language", null: false
    t.string "document_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_template_id", "language", "document_type"], name: "index_related_documents_on_template_id_and_language_and_type", unique: true
    t.index ["form_template_id"], name: "index_form_template_related_documents_on_form_template_id"
  end

  create_table "form_templates", force: :cascade do |t|
    t.string "identifier", null: false
    t.integer "version_major", null: false
    t.integer "version_minor", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier", "version_major", "version_minor"], name: "index_form_templates_on_identifier_and_version", unique: true
  end

end
