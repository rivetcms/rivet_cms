module RivetCms
  module FieldValues
    class Text < Base
      self.table_name = "rivet_cms_field_values_texts"

      validates :value, presence: true, if: :required?
    end
  end
end
