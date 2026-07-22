module RivetCms
  class ComponentInstance < ApplicationRecord
    include RevisionOwned

    has_prefix_id :cmpi

    belongs_to :field
    belongs_to :component

    has_many :content_values, as: :owner, dependent: :destroy
    has_many :relations, as: :owner, dependent: :destroy
    has_many :component_instances, as: :owner, dependent: :destroy

    validate :component_in_same_organization

    scope :ordered, -> { order(:position) }

    private

    def component_in_same_organization
      return if component.nil? || owner_organization_id.nil?
      return if component.organization_id == owner_organization_id

      errors.add(:component, "must belong to the same organization")
    end
  end
end
