module RivetCms
  module FieldValues
    class Base < ApplicationRecord
      self.abstract_class = true
      
      def self.table_name_prefix
        "rivet_cms_field_values_"
      end
    end
  end
end