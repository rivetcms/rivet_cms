module RivetCms
  class ApplicationController < ActionController::Base
    layout "rivet_cms/application"

    before_action :set_current_tenant
    after_action :set_csrf_cookie

    inertia_config version: -> { RivetCms.asset_version }

    inertia_share app_version: RivetCms::VERSION,
                  flash: -> { { notice: flash.notice, alert: flash.alert } },
                  paths: -> {
                    {
                      root: root_path,
                      content_types: content_types_path,
                      new_content_type: new_content_type_path,
                      components: components_path,
                      new_component: new_component_path
                    }
                  }

    private

    # Inertia (axios) reads the XSRF-TOKEN cookie and sends it back as a header.
    def set_csrf_cookie
      cookies["XSRF-TOKEN"] = form_authenticity_token
    end

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
