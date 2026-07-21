module RivetCms
  module FieldValues
    class Boolean < Base
      self.table_name = "rivet_cms_field_values_booleans"

      validates :value, inclusion: { in: [ true, false ] }
    end
  end
end
