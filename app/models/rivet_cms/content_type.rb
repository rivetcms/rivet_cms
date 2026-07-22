module RivetCms
  class ContentType < ApplicationRecord
    include Sluggable

    has_prefix_id :ctype
    include OrganizationScoped

    has_many :fields, dependent: :destroy
    has_many :documents, dependent: :destroy

    validates :name, presence: true
    validates :slug, uniqueness: { scope: :organization_id }
    validates :single, inclusion: { in: [ true, false ] }

    scope :singles, -> { where(single: true) }
    scope :collections, -> { where(single: false) }

    def collection?
      !single?
    end

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
