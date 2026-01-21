module RivetCms
  module FieldValues
    class Integer < Base
      self.table_name = "rivet_cms_field_values_integers"

      validates :value, presence: true, if: :required?
      validates :value, numericality: { only_integer: true }, allow_nil: true
    end
  end
end
