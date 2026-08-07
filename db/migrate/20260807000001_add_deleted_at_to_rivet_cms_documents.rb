class AddDeletedAtToRivetCmsDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :rivet_cms_documents, :deleted_at, :datetime
    add_index :rivet_cms_documents, :deleted_at
  end
end
