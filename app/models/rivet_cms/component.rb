module RivetCms
  class Component < ApplicationRecord
    include Sluggable

    has_prefix_id :comp
    include OrganizationScoped

    belongs_to :category
    has_many :fields, dependent: :destroy

    validates :name, presence: true
    validates :slug, uniqueness: { scope: :organization_id }

    # Get fields including soft-deleted ones
    def all_fields
      fields.with_discarded
    end

    # Get only active (non-deleted) fields
    def active_fields
      fields
    end

    # Get only soft-deleted fields
    def discarded_fields
      fields.with_discarded.discarded
    end
  end
end
