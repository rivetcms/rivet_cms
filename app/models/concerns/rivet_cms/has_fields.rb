module RivetCms
  # Shared by content types and components. The fields association is
  # soft-delete scoped (kept only), so dependent: :destroy would leave
  # discarded fields holding the FK — destroy those explicitly on delete.
  module HasFields
    extend ActiveSupport::Concern

    included do
      has_many :fields, dependent: :destroy
      before_destroy :destroy_discarded_fields, prepend: true
    end

    def all_fields
      fields.with_discarded
    end

    def active_fields
      fields
    end

    def discarded_fields
      fields.with_discarded.discarded
    end

    private

    def destroy_discarded_fields
      discarded_fields.destroy_all
    end
  end
end
