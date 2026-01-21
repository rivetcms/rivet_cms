# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_20_044315) do
  create_table "rivet_cms_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.boolean "system", default: false, null: false
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rivet_cms_categories_on_name"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_categories_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_categories_on_organization_id"
  end

  create_table "rivet_cms_components", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "repeatable", default: false, null: false
    t.integer "category_id"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_rivet_cms_components_on_category_id"
    t.index ["name"], name: "index_rivet_cms_components_on_name"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_components_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_components_on_organization_id"
  end

  create_table "rivet_cms_content_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "single", default: false
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rivet_cms_content_types_on_name"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_content_types_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_content_types_on_organization_id"
  end

  create_table "rivet_cms_content_values", force: :cascade do |t|
    t.integer "content_id", null: false
    t.integer "field_id", null: false
    t.string "value_type", null: false
    t.integer "value_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id", "field_id"], name: "index_rivet_cms_content_values_on_content_id_and_field_id", unique: true
    t.index ["content_id"], name: "index_rivet_cms_content_values_on_content_id"
    t.index ["field_id"], name: "index_rivet_cms_content_values_on_field_id"
    t.index ["value_type", "value_id"], name: "index_rivet_cms_content_values_on_value"
  end

  create_table "rivet_cms_contents", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "content_type_id", null: false
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "unpublished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type_id"], name: "index_rivet_cms_contents_on_content_type_id"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_contents_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_contents_on_organization_id"
    t.index ["status"], name: "index_rivet_cms_contents_on_status"
  end

  create_table "rivet_cms_field_values_attachments", force: :cascade do |t|
    t.integer "attachment_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_booleans", force: :cascade do |t|
    t.boolean "value", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_integers", force: :cascade do |t|
    t.integer "value", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_strings", force: :cascade do |t|
    t.string "value", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_texts", force: :cascade do |t|
    t.text "value", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_fields", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "content_type_id"
    t.integer "component_id"
    t.string "name", null: false
    t.integer "field_type", default: 0, null: false
    t.text "description"
    t.boolean "required", default: false, null: false
    t.json "options", default: {}
    t.integer "position", default: 0, null: false
    t.string "width", default: "full", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "row", default: 0, null: false
    t.index ["component_id", "name"], name: "idx_fields_component_name_unique", unique: true, where: "deleted_at IS NULL /*application='Dummy'*/"
    t.index ["component_id"], name: "index_rivet_cms_fields_on_component_id"
    t.index ["content_type_id", "name"], name: "idx_fields_content_type_name_unique", unique: true, where: "deleted_at IS NULL /*application='Dummy'*/"
    t.index ["content_type_id"], name: "index_rivet_cms_fields_on_content_type_id"
    t.index ["deleted_at"], name: "index_rivet_cms_fields_on_deleted_at"
    t.index ["organization_id"], name: "index_rivet_cms_fields_on_organization_id"
    t.index ["position"], name: "index_rivet_cms_fields_on_position"
  end

  create_table "rivet_cms_organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "domain", null: false
    t.string "subdomain"
    t.boolean "default", default: false, null: false
    t.string "timezone", default: "UTC"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_rivet_cms_organizations_on_domain", unique: true
    t.index ["subdomain"], name: "index_rivet_cms_organizations_on_subdomain"
  end

  create_table "rivet_cms_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.integer "invited_by_id"
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.datetime "deleted_at"
    t.integer "deleted_by_id"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_at"], name: "index_rivet_cms_users_on_accepted_at"
    t.index ["deleted_at"], name: "index_rivet_cms_users_on_deleted_at"
    t.index ["deleted_by_id"], name: "index_rivet_cms_users_on_deleted_by_id"
    t.index ["email_address"], name: "index_rivet_cms_users_on_email_address", unique: true
    t.index ["invited_by_id"], name: "index_rivet_cms_users_on_invited_by_id"
    t.index ["name"], name: "index_rivet_cms_users_on_name"
    t.index ["organization_id"], name: "index_rivet_cms_users_on_organization_id"
  end

  add_foreign_key "rivet_cms_categories", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_components", "rivet_cms_categories", column: "category_id"
  add_foreign_key "rivet_cms_components", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_content_types", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_content_values", "rivet_cms_contents", column: "content_id"
  add_foreign_key "rivet_cms_content_values", "rivet_cms_fields", column: "field_id"
  add_foreign_key "rivet_cms_contents", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_contents", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_components", column: "component_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_users", column: "deleted_by_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_users", column: "invited_by_id"
end
