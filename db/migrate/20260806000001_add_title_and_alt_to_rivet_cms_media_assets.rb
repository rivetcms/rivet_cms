class AddTitleAndAltToRivetCmsMediaAssets < ActiveRecord::Migration[7.0]
  def change
    add_column :rivet_cms_media_assets, :title, :string
    add_column :rivet_cms_media_assets, :alt, :string
    add_column :rivet_cms_media_assets, :description, :text
  end
end
