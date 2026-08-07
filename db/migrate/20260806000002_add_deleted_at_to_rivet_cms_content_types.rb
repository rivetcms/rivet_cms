class AddDeletedAtToRivetCmsContentTypes < ActiveRecord::Migration[7.2]
  def change
    add_column :rivet_cms_content_types, :deleted_at, :datetime
    add_index :rivet_cms_content_types, :deleted_at
  end
end
