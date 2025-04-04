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

ActiveRecord::Schema[7.2].define(version: 2025_03_21_210857) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "rivet_cms_components", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "repeatable", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "slug"], name: "index_rivet_cms_components_on_site_id_and_slug", unique: true
  end

  create_table "rivet_cms_content_types", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "is_single", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "slug"], name: "index_rivet_cms_content_types_on_site_id_and_slug", unique: true
  end

  create_table "rivet_cms_content_values", force: :cascade do |t|
    t.bigint "content_id", null: false
    t.bigint "field_id", null: false
    t.string "value_type", null: false
    t.bigint "value_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_rivet_cms_content_values_on_content_id"
    t.index ["field_id"], name: "index_rivet_cms_content_values_on_field_id"
    t.index ["value_type", "value_id"], name: "index_rivet_cms_content_values_on_value"
  end

  create_table "rivet_cms_contents", force: :cascade do |t|
    t.integer "site_id", null: false
    t.bigint "content_type_id", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.datetime "unpublished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type_id"], name: "index_rivet_cms_contents_on_content_type_id"
    t.index ["slug"], name: "index_rivet_cms_contents_on_slug", unique: true
    t.index ["status"], name: "index_rivet_cms_contents_on_status"
  end

  create_table "rivet_cms_field_values_booleans", force: :cascade do |t|
    t.boolean "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_integers", force: :cascade do |t|
    t.integer "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_strings", force: :cascade do |t|
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_field_values_texts", force: :cascade do |t|
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rivet_cms_fields", force: :cascade do |t|
    t.bigint "component_id"
    t.bigint "content_type_id"
    t.string "name", null: false
    t.string "field_type", null: false
    t.text "description"
    t.boolean "required", default: false
    t.jsonb "options", default: {}
    t.integer "position"
    t.string "width", default: "full"
    t.integer "row_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id", "name"], name: "index_fields_on_component_id_and_name", unique: true
    t.index ["component_id"], name: "index_rivet_cms_fields_on_component_id"
    t.index ["content_type_id", "name"], name: "index_fields_on_content_type_id_and_name", unique: true
    t.index ["content_type_id"], name: "index_rivet_cms_fields_on_content_type_id"
    t.index ["position"], name: "index_rivet_cms_fields_on_position"
    t.check_constraint "component_id IS NOT NULL AND content_type_id IS NULL OR component_id IS NULL AND content_type_id IS NOT NULL", name: "field_owner_check"
  end

  create_table "rivet_cms_invitations", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "email", null: false
    t.string "token_digest", null: false
    t.bigint "inviter_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inviter_id"], name: "index_rivet_cms_invitations_on_inviter_id"
    t.index ["site_id", "email"], name: "index_rivet_cms_invitations_on_site_id_and_email", unique: true
    t.index ["site_id", "token_digest"], name: "index_rivet_cms_invitations_on_site_id_and_token_digest", unique: true
  end

  create_table "rivet_cms_sessions", force: :cascade do |t|
    t.integer "site_id", null: false
    t.bigint "user_id", null: false
    t.string "ip_address", null: false
    t.string "user_agent", null: false
    t.string "remember_digest"
    t.datetime "remember_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["remember_digest"], name: "index_rivet_cms_sessions_on_remember_digest", unique: true
    t.index ["user_id"], name: "index_rivet_cms_sessions_on_user_id"
  end

  create_table "rivet_cms_users", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.bigint "invited_by_id"
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.datetime "deleted_at"
    t.bigint "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_by_id"], name: "index_rivet_cms_users_on_deleted_by_id"
    t.index ["invited_by_id"], name: "index_rivet_cms_users_on_invited_by_id"
    t.index ["site_id", "email"], name: "index_rivet_cms_users_on_site_id_and_email", unique: true
  end

  add_foreign_key "rivet_cms_content_values", "rivet_cms_contents", column: "content_id"
  add_foreign_key "rivet_cms_content_values", "rivet_cms_fields", column: "field_id"
  add_foreign_key "rivet_cms_contents", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_components", column: "component_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_invitations", "rivet_cms_users", column: "inviter_id"
  add_foreign_key "rivet_cms_sessions", "rivet_cms_users", column: "user_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_users", column: "deleted_by_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_users", column: "invited_by_id"
end
