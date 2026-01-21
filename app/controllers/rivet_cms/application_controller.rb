module RivetCms
  class ApplicationController < ActionController::Base
    layout "rivet_cms/application"

    before_action :set_current_tenant

    private

    # TODO: Replace with proper tenant selection based on authentication
    # This is a temporary solution for development
    def set_current_tenant
      # Try to find organization by domain or use the first one
      organization = Organization.find_by(domain: request.host) ||
                     Organization.find_by(domain: "localhost") ||
                     Organization.first

      if organization
        ActsAsTenant.current_tenant = organization
      else
        # In development, create a default org if none exists
        if Rails.env.development? || Rails.env.test?
          organization = Organization.create!(
            name: "Development Org",
            domain: "localhost",
            subdomain: "dev"
          )
          ActsAsTenant.current_tenant = organization
        end
      end
    end
  end
end
