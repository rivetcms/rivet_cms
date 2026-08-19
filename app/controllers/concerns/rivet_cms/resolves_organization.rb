module RivetCms
  # Host-based organization lookup, shared by the admin controllers and the
  # delivery API's public mode (token mode resolves from the token instead).
  module ResolvesOrganization
    private

    def set_current_organization
      RivetCms::Current.organization =
        Organization.find_by(domain: request.host) ||
        Organization.find_by(domain: "localhost") ||
        Organization.first ||
        default_organization
    end

    def default_organization
      return unless Rails.env.development? || Rails.env.test?

      Organization.create!(name: "Development Org", domain: "localhost", subdomain: "dev")
    end
  end
end
