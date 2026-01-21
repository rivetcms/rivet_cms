class AddRowToRivetCmsFields < ActiveRecord::Migration[7.2]
  def change
    add_column :rivet_cms_fields, :row, :integer, default: 0, null: false

    # Backfill existing fields: each field gets its own row based on position
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE rivet_cms_fields
          SET row = position
        SQL
      end
    end
  end
end
