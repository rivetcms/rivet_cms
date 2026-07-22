class CreateRivetCmsContentTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_content_types do |t|
      t.string :name, null: false, index: true
      t.string :slug, null: false
      t.text :description
      t.boolean :single, default: false
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: false
      t.timestamps

      t.index [ :organization_id, :slug ], unique: true
    end
  end
end
