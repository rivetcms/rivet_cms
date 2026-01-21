class CreateRivetCmsContentTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :rivet_cms_content_types do |t|
      t.string :name, null: false, index: true
      t.string :slug, null: false
      t.text :description
      t.boolean :single, default: false
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: true
      t.timestamps

      t.index :slug, unique: true
    end
  end
end
