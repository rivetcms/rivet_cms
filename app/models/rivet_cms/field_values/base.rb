module RivetCms
  module FieldValues
    class Base < ApplicationRecord
      self.abstract_class = true

      attr_accessor :required

      def self.table_name_prefix
        "rivet_cms_field_values_"
      end

      def required?
        required == true
      end
    end
  end
end
