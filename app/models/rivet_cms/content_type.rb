module RivetCms
  class ContentType < ApplicationRecord
    include Sluggable

    has_prefix_id :ctype
    include OrganizationScoped
    include HasFields

    has_many :documents, dependent: :destroy

    validates :name, presence: true
    validates :slug, uniqueness: { scope: :organization_id }
    validates :single, inclusion: { in: [ true, false ] }

    scope :singles, -> { where(single: true) }
    scope :collections, -> { where(single: false) }

    def collection?
      !single?
    end
  end
end
