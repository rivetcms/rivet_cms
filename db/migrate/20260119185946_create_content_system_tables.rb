class CreateContentSystemTables < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_fields do |t|
      t.references :organization, null: false, foreign_key: { to_table: :rivet_cms_organizations }
      t.references :content_type, foreign_key: { to_table: :rivet_cms_content_types }
      t.references :component, foreign_key: { to_table: :rivet_cms_components }
      t.string :key, null: false
      t.string :label, null: false
      t.integer :field_type, null: false, default: 0
      t.text :description
      t.boolean :required, default: false, null: false
      t.integer :min_items
      t.integer :max_items
      # No DB default: MySQL rejects defaults on JSON columns. The Field model
      # defaults it to {} instead.
      t.json :config
      t.integer :position, default: 0, null: false
      t.integer :row, default: 0, null: false
      t.string :width, default: "full", null: false
      t.datetime :deleted_at
      t.timestamps

      t.index [ :content_type_id, :key ]
      t.index [ :component_id, :key ]
      t.index :deleted_at
      t.index :position
    end

    create_table :rivet_cms_documents do |t|
      t.references :organization, null: false, foreign_key: { to_table: :rivet_cms_organizations }
      t.references :content_type, null: false, foreign_key: { to_table: :rivet_cms_content_types }
      t.string :slug, null: false
      t.string :singleton_key
      t.bigint :published_revision_id
      t.bigint :draft_revision_id
      t.timestamps

      t.index [ :content_type_id, :slug ], unique: true
      t.index [ :content_type_id, :singleton_key ], unique: true
      t.index :published_revision_id
      t.index :draft_revision_id
    end

    create_table :rivet_cms_document_revisions do |t|
      t.references :document, null: false, foreign_key: { to_table: :rivet_cms_documents }
      t.string :locale, null: false, default: "en"
      t.integer :schema_version, null: false, default: 1
      t.references :author, polymorphic: true
      t.string :author_name
      t.integer :state, null: false, default: 0
      t.datetime :published_at
      t.timestamps

      t.index [ :document_id, :state ]
      t.index [ :document_id, :locale ]
    end

    add_foreign_key :rivet_cms_documents, :rivet_cms_document_revisions, column: :published_revision_id
    add_foreign_key :rivet_cms_documents, :rivet_cms_document_revisions, column: :draft_revision_id

    create_table :rivet_cms_content_values do |t|
      t.references :owner, polymorphic: true, null: false, index: false
      t.references :field, null: false, foreign_key: { to_table: :rivet_cms_fields }
      t.string :string_value
      t.text :text_value
      t.integer :integer_value
      t.boolean :boolean_value
      t.decimal :decimal_value, precision: 19, scale: 6
      t.datetime :datetime_value
      t.date :date_value
      t.json :json_value
      t.timestamps

      t.index [ :owner_type, :owner_id, :field_id ], unique: true, name: "idx_content_values_owner_field"
    end

    create_table :rivet_cms_relations do |t|
      t.references :owner, polymorphic: true, null: false, index: false
      t.references :field, null: false, foreign_key: { to_table: :rivet_cms_fields }
      t.references :target_document, null: false, foreign_key: { to_table: :rivet_cms_documents }
      t.integer :position, null: false, default: 0
      t.timestamps

      t.index [ :owner_type, :owner_id, :field_id, :position ], name: "idx_relations_owner_field_pos"
    end

    create_table :rivet_cms_component_instances do |t|
      t.references :owner, polymorphic: true, null: false, index: false
      t.references :field, null: false, foreign_key: { to_table: :rivet_cms_fields }
      t.references :component, null: false, foreign_key: { to_table: :rivet_cms_components }
      t.integer :position, null: false, default: 0
      t.timestamps

      t.index [ :owner_type, :owner_id, :field_id, :position ], name: "idx_cmpi_owner_field_pos"
    end
  end
end
