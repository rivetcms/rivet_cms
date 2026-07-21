class FixSlugIndexes < ActiveRecord::Migration[7.2]
  def change
    # ContentType: change global unique index to org-scoped
    remove_index :rivet_cms_content_types, :slug
    add_index :rivet_cms_content_types, [ :organization_id, :slug ], unique: true

    # Component: add unique constraint scoped to organization
    remove_index :rivet_cms_components, :slug
    add_index :rivet_cms_components, [ :organization_id, :slug ], unique: true
  end
end
