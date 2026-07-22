class CreateRivetCmsCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_categories do |t|
      t.string :name, null: false, index: true
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :system, default: false, null: false
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: false

      t.timestamps
      t.index [ :organization_id, :slug ], unique: true
    end
  end
end
