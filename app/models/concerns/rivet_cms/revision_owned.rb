module RivetCms
  class RevisionImmutableError < StandardError; end

  module RevisionOwned
    extend ActiveSupport::Concern

    included do
      belongs_to :owner, polymorphic: true
      before_update :guard_published_owner!
      validate :field_matches_owner_organization
    end

    def owning_revision
      node = owner
      node = node.owner while node.is_a?(ComponentInstance)
      node if node.is_a?(DocumentRevision)
    end

    def owner_organization_id
      owning_revision&.document&.organization_id
    end

    private

    def guard_published_owner!
      raise RevisionImmutableError, "cannot modify a published revision" if owning_revision&.published?
    end

    def field_matches_owner_organization
      return if field.nil? || owner_organization_id.nil?
      return if field.organization_id == owner_organization_id

      errors.add(:field, "must belong to the same organization")
    end
  end
end
