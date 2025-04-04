module RivetCms
  module FieldValues
    class Markdown < Base
      # Share the same table as text fields
      def self.table_name
        "rivet_cms_field_values_text"
      end
    end
  end
end
