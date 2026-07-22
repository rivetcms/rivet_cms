module RivetCms
  class ContentValue < ApplicationRecord
    include RevisionOwned
    include TypedValue

    has_prefix_id :val

    belongs_to :field
    belongs_to :media_asset, class_name: "RivetCms::MediaAsset", optional: true

    validates :field_id, uniqueness: { scope: [ :owner_type, :owner_id ] }
    validate :media_asset_matches_owner_organization

    private

    def media_asset_matches_owner_organization
      return if media_asset.nil? || owner_organization_id.nil?
      return if media_asset.organization_id == owner_organization_id

      errors.add(:media_asset, "must belong to the same organization")
    end
  end
end
