class CreateRivetCmsComponents < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_components do |t|
      t.string :name, null: false, index: true
      t.string :slug, null: false
      t.text :description
      # The FK is added in the categories migration, which runs later; adding
      # it here would reference a table that does not exist yet (fine on
      # SQLite, fatal on Postgres).
      t.references :category
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: false
      t.timestamps

      t.index [ :organization_id, :slug ], unique: true
    end
  end
end
