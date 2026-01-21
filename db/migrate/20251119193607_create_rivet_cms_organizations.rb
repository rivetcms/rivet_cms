class CreateRivetCmsOrganizations < ActiveRecord::Migration[7.2]
  def change
    create_table :rivet_cms_organizations do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.string :subdomain
      t.boolean :default, default: false, null: false
      t.string :timezone, default: "UTC"

      t.timestamps

      t.index :domain, unique: true
      # Index on subdomain for lookups (uniqueness handled at model level)
      t.index :subdomain
    end
  end
end
