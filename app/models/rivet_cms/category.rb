module RivetCms
  class Category < ApplicationRecord
    has_prefix_id :cat
    include OrganizationScoped

    has_many :components, dependent: :restrict_with_error

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: :organization_id }
    validates :system, inclusion: { in: [ true, false ] }

    scope :system_categories, -> { where(system: true) }
    scope :custom_categories, -> { where(system: false) }
    scope :ordered, -> { order(:position) }

    def destroyable?
      !system? && components.empty?
    end
  end
end
