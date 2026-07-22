module RivetCms
  class Relation < ApplicationRecord
    include RevisionOwned

    has_prefix_id :rel

    belongs_to :field
    belongs_to :target_document, class_name: "RivetCms::Document"

    validate :target_in_same_organization

    scope :ordered, -> { order(:position) }

    private

    def target_in_same_organization
      return if target_document.nil? || owner_organization_id.nil?
      return if target_document.organization_id == owner_organization_id

      errors.add(:target_document, "must belong to the same organization")
    end
  end
end
