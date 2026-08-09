class CreateRivetCmsUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :rivet_cms_users do |t|
      t.references :organization, null: false, foreign_key: { to_table: :rivet_cms_organizations }
      t.string :name, null: false
      t.string :email, null: false
      # Null until the invite link is used; a pending user cannot sign in
      t.string :password_digest
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :rivet_cms_users, [ :organization_id, :email ], unique: true
  end
end
