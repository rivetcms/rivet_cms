module RivetCms
  module FieldValues
    class String < Base
      self.table_name = "rivet_cms_field_values_strings"

      validates :value, presence: true, if: :required?
    end
  end
end
