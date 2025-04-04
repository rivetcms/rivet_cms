class CreateCoreTables < ActiveRecord::Migration[7.2]
  def change
    def json_or_text
      if connection.adapter_name.downcase == "mysql2"
        mysql_version = connection.select_value("SELECT VERSION()")
        Gem::Version.new(mysql_version) >= Gem::Version.new("5.7.8") ? :json : :text
      else
        :jsonb
      end
    end

    create_table :rivet_cms_content_types do |t|
      t.integer :site_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :is_single, default: false
      t.timestamps

      t.index [:site_id, :slug], unique: true
    end

    create_table :rivet_cms_components do |t|
      t.integer :site_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :repeatable, default: false
      t.timestamps

      t.index [:site_id, :slug], unique: true
    end

    create_table :rivet_cms_fields do |t|
      t.references :component, null: true, foreign_key: { to_table: :rivet_cms_components }
      t.references :content_type, null: true, foreign_key: { to_table: :rivet_cms_content_types }
      t.string :name, null: false
      t.string :field_type, null: false
      t.text :description
      t.boolean :required, default: false
      t.column :options, json_or_text, default: {}
      t.integer :position
      t.string :width, default: "full"
      t.integer :row_group
      t.timestamps

      t.index [:content_type_id, :name], unique: true, name: "index_fields_on_content_type_id_and_name"
      t.index [:component_id, :name], unique: true, name: "index_fields_on_component_id_and_name"
      t.index :position
      t.check_constraint "(component_id IS NOT NULL AND content_type_id IS NULL) OR (component_id IS NULL AND content_type_id IS NOT NULL)", name: "field_owner_check"
    end

    create_table :rivet_cms_contents do |t|
      t.integer :site_id, null: false
      t.references :content_type, null: false, foreign_key: { to_table: :rivet_cms_content_types }
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :unpublished_at
      t.timestamps

      t.index :slug, unique: true
      t.index :status
    end

    create_table :rivet_cms_content_values do |t|
      t.references :content, null: false, foreign_key: { to_table: :rivet_cms_contents }
      t.references :field, null: false, foreign_key: { to_table: :rivet_cms_fields }
      t.references :value, polymorphic: true, null: false
      t.timestamps
    end

    create_table :rivet_cms_field_values_strings do |t|
      t.string :value, null: false
      t.timestamps
    end

    create_table :rivet_cms_field_values_texts do |t|
      t.text :value, null: false
      t.timestamps
    end

    create_table :rivet_cms_field_values_booleans do |t|
      t.boolean :value, null: false
      t.timestamps
    end

    create_table :rivet_cms_field_values_integers do |t|
      t.integer :value, null: false
      t.timestamps
    end
  end
end