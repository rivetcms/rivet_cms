module RivetCms
  class ApplicationController < ActionController::Base
    layout "rivet_cms/application"

    before_action :set_current_organization
    after_action :set_csrf_cookie

    inertia_config version: -> { RivetCms.asset_version }

    inertia_share app_version: RivetCms::VERSION,
                  flash: -> { { notice: flash.notice, alert: flash.alert } },
                  paths: -> {
                    {
                      root: root_path,
                      content: content_path,
                      media: media_assets_path,
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

    # TODO: Pro replaces this with host/subdomain resolution and authentication.
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
