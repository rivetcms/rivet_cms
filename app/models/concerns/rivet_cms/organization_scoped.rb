module RivetCms
  module OrganizationScoped
    extend ActiveSupport::Concern

    included do
      belongs_to :organization
      before_validation :assign_default_organization
      validates :organization, presence: true
    end

    private

    def assign_default_organization
      self.organization ||= RivetCms::Current.organization
    end
  end
end
