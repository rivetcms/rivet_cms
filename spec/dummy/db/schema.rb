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

ActiveRecord::Schema[7.2].define(version: 2026_08_08_000001) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "rivet_cms_api_tokens", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "token_last4", null: false
    t.integer "scope", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_rivet_cms_api_tokens_on_organization_id"
    t.index ["token_digest"], name: "index_rivet_cms_api_tokens_on_token_digest", unique: true
  end

  create_table "rivet_cms_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.boolean "system", default: false, null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rivet_cms_categories_on_name"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_categories_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_categories_on_organization_id"
  end

  create_table "rivet_cms_component_instances", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.integer "field_id", null: false
    t.integer "component_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_rivet_cms_component_instances_on_component_id"
    t.index ["field_id"], name: "index_rivet_cms_component_instances_on_field_id"
    t.index ["owner_type", "owner_id", "field_id", "position"], name: "idx_cmpi_owner_field_pos"
  end

  create_table "rivet_cms_components", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "category_id"
    t.integer "organization_id", null: false
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
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_rivet_cms_content_types_on_deleted_at"
    t.index ["name"], name: "index_rivet_cms_content_types_on_name"
    t.index ["organization_id", "slug"], name: "index_rivet_cms_content_types_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_content_types_on_organization_id"
  end

  create_table "rivet_cms_content_values", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.integer "field_id", null: false
    t.string "string_value"
    t.text "text_value"
    t.integer "integer_value"
    t.boolean "boolean_value"
    t.decimal "decimal_value", precision: 19, scale: 6
    t.datetime "datetime_value"
    t.date "date_value"
    t.json "json_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "media_asset_id"
    t.index ["field_id"], name: "index_rivet_cms_content_values_on_field_id"
    t.index ["media_asset_id"], name: "index_rivet_cms_content_values_on_media_asset_id"
    t.index ["owner_type", "owner_id", "field_id"], name: "idx_content_values_owner_field", unique: true
  end

  create_table "rivet_cms_document_revisions", force: :cascade do |t|
    t.integer "document_id", null: false
    t.string "locale", default: "en", null: false
    t.integer "schema_version", default: 1, null: false
    t.string "author_type"
    t.integer "author_id"
    t.string "author_name"
    t.integer "state", default: 0, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_rivet_cms_document_revisions_on_author"
    t.index ["document_id", "locale"], name: "index_rivet_cms_document_revisions_on_document_id_and_locale"
    t.index ["document_id", "state"], name: "index_rivet_cms_document_revisions_on_document_id_and_state"
    t.index ["document_id"], name: "index_rivet_cms_document_revisions_on_document_id"
  end

  create_table "rivet_cms_documents", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "content_type_id", null: false
    t.string "slug", null: false
    t.string "singleton_key"
    t.bigint "published_revision_id"
    t.bigint "draft_revision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["content_type_id", "singleton_key"], name: "index_rivet_cms_documents_on_content_type_id_and_singleton_key", unique: true
    t.index ["content_type_id", "slug"], name: "index_rivet_cms_documents_on_content_type_id_and_slug", unique: true
    t.index ["content_type_id"], name: "index_rivet_cms_documents_on_content_type_id"
    t.index ["deleted_at"], name: "index_rivet_cms_documents_on_deleted_at"
    t.index ["draft_revision_id"], name: "index_rivet_cms_documents_on_draft_revision_id"
    t.index ["organization_id"], name: "index_rivet_cms_documents_on_organization_id"
    t.index ["published_revision_id"], name: "index_rivet_cms_documents_on_published_revision_id"
  end

  create_table "rivet_cms_fields", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "content_type_id"
    t.integer "component_id"
    t.string "key", null: false
    t.string "label", null: false
    t.integer "field_type", default: 0, null: false
    t.text "description"
    t.boolean "required", default: false, null: false
    t.integer "min_items"
    t.integer "max_items"
    t.json "config"
    t.integer "position", default: 0, null: false
    t.integer "row", default: 0, null: false
    t.string "width", default: "full", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id", "key"], name: "index_rivet_cms_fields_on_component_id_and_key"
    t.index ["component_id"], name: "index_rivet_cms_fields_on_component_id"
    t.index ["content_type_id", "key"], name: "index_rivet_cms_fields_on_content_type_id_and_key"
    t.index ["content_type_id"], name: "index_rivet_cms_fields_on_content_type_id"
    t.index ["deleted_at"], name: "index_rivet_cms_fields_on_deleted_at"
    t.index ["organization_id"], name: "index_rivet_cms_fields_on_organization_id"
    t.index ["position"], name: "index_rivet_cms_fields_on_position"
  end

  create_table "rivet_cms_media_assets", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "filename"
    t.string "content_type"
    t.bigint "byte_size"
    t.integer "kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "alt"
    t.text "description"
    t.index ["organization_id"], name: "index_rivet_cms_media_assets_on_organization_id"
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

  create_table "rivet_cms_relations", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.integer "field_id", null: false
    t.integer "target_document_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_rivet_cms_relations_on_field_id"
    t.index ["owner_type", "owner_id", "field_id", "position"], name: "idx_relations_owner_field_pos"
    t.index ["target_document_id"], name: "index_rivet_cms_relations_on_target_document_id"
  end

  create_table "rivet_cms_users", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_rivet_cms_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_rivet_cms_users_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "rivet_cms_api_tokens", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_categories", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_component_instances", "rivet_cms_components", column: "component_id"
  add_foreign_key "rivet_cms_component_instances", "rivet_cms_fields", column: "field_id"
  add_foreign_key "rivet_cms_components", "rivet_cms_categories", column: "category_id"
  add_foreign_key "rivet_cms_components", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_content_types", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_content_values", "rivet_cms_fields", column: "field_id"
  add_foreign_key "rivet_cms_content_values", "rivet_cms_media_assets", column: "media_asset_id"
  add_foreign_key "rivet_cms_document_revisions", "rivet_cms_documents", column: "document_id"
  add_foreign_key "rivet_cms_documents", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_documents", "rivet_cms_document_revisions", column: "draft_revision_id"
  add_foreign_key "rivet_cms_documents", "rivet_cms_document_revisions", column: "published_revision_id"
  add_foreign_key "rivet_cms_documents", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_components", column: "component_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_content_types", column: "content_type_id"
  add_foreign_key "rivet_cms_fields", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_media_assets", "rivet_cms_organizations", column: "organization_id"
  add_foreign_key "rivet_cms_relations", "rivet_cms_documents", column: "target_document_id"
  add_foreign_key "rivet_cms_relations", "rivet_cms_fields", column: "field_id"
  add_foreign_key "rivet_cms_users", "rivet_cms_organizations", column: "organization_id"
end
