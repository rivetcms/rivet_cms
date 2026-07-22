class CreateRivetCmsUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_users do |t|
      t.string :name, null: false, index: true
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0
      t.references :invited_by, foreign_key: { to_table: :rivet_cms_users }
      t.datetime :invited_at
      t.datetime :accepted_at, index: true
      t.datetime :deleted_at, index: true
      t.references :deleted_by, foreign_key: { to_table: :rivet_cms_users }
      t.references :organization, foreign_key: { to_table: :rivet_cms_organizations }, null: false

      t.timestamps

      t.index :email_address, unique: true
    end
  end
end
