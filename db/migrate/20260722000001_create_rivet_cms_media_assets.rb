class CreateRivetCmsMediaAssets < ActiveRecord::Migration[7.0]
  def change
    create_table :rivet_cms_media_assets do |t|
      t.references :organization, null: false, foreign_key: { to_table: :rivet_cms_organizations }
      t.string :filename
      t.string :content_type
      t.bigint :byte_size
      t.integer :kind, null: false, default: 0
      t.timestamps
    end

    add_reference :rivet_cms_content_values, :media_asset,
                  foreign_key: { to_table: :rivet_cms_media_assets }
  end
end
