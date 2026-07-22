class CreateRivetCmsApiTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_api_tokens do |t|
      t.references :organization, null: false, foreign_key: { to_table: :rivet_cms_organizations }
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_last4, null: false
      t.integer :scope, null: false, default: 0
      t.datetime :last_used_at
      t.datetime :expires_at
      t.timestamps

      t.index :token_digest, unique: true
    end
  end
end
