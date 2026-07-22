module RivetCms
  class Component < ApplicationRecord
    include Sluggable

    has_prefix_id :comp
    include OrganizationScoped
    include HasFields

    belongs_to :category

    validates :name, presence: true
    validates :slug, uniqueness: { scope: :organization_id }
  end
end
