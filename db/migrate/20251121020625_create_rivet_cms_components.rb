class CreateRivetCmsComponents < ActiveRecord::Migration[7.2]
  def change
    create_table :rivet_cms_components do |t|
      t.string :name, null: false, index: true
      t.string :slug, null: false, index: true
      t.text :description
      t.boolean :repeatable, default: false, null: false
      t.references :category, foreign_key: { to_table: :rivet_cms_categories }
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: true
      t.timestamps
    end
  end
end
