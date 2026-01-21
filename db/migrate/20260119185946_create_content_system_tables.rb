class CreateContentSystemTables < ActiveRecord::Migration[7.2]
  def change
    # Fields define the schema for content types and components
    create_table :rivet_cms_fields do |t|
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }
      t.references :content_type, foreign_key: { to_table: :rivet_cms_content_types }
      t.references :component, foreign_key: { to_table: :rivet_cms_components }
      t.string :name, null: false
      t.integer :field_type, null: false, default: 0
      t.text :description
      t.boolean :required, default: false, null: false
      t.json :options, default: {}
      t.integer :position, default: 0, null: false
      t.string :width, default: "full", null: false
      t.datetime :deleted_at
      t.timestamps

      t.index [:content_type_id, :name], unique: true, where: "deleted_at IS NULL", name: "idx_fields_content_type_name_unique"
      t.index [:component_id, :name], unique: true, where: "deleted_at IS NULL", name: "idx_fields_component_name_unique"
      t.index :deleted_at
      t.index :position
    end

    # Content entries (instances of content types)
    create_table :rivet_cms_contents do |t|
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }
      t.references :content_type, null: false, foreign_key: { to_table: :rivet_cms_content_types }
      t.string :slug, null: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.datetime :unpublished_at
      t.timestamps

      t.index [:organization_id, :slug], unique: true
      t.index :status
    end

    # Content values join content + field + polymorphic value
    create_table :rivet_cms_content_values do |t|
      t.references :content, null: false, foreign_key: { to_table: :rivet_cms_contents }
      t.references :field, null: false, foreign_key: { to_table: :rivet_cms_fields }
      t.references :value, polymorphic: true, null: false
      t.timestamps

      t.index [:content_id, :field_id], unique: true
    end

    # Field value tables for different types
    create_table :rivet_cms_field_values_strings do |t|
      t.string :value, null: false, default: ""
      t.timestamps
    end

    create_table :rivet_cms_field_values_texts do |t|
      t.text :value, null: false, default: ""
      t.timestamps
    end

    create_table :rivet_cms_field_values_integers do |t|
      t.integer :value, null: false, default: 0
      t.timestamps
    end

    create_table :rivet_cms_field_values_booleans do |t|
      t.boolean :value, null: false, default: false
      t.timestamps
    end

    # Unified attachment table for images, videos, and files
    create_table :rivet_cms_field_values_attachments do |t|
      t.integer :attachment_type, null: false, default: 0
      t.timestamps
    end
  end
end
