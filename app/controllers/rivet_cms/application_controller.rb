module RivetCms
  # Inherits from the host-configured parent controller so host auth filters and
  # helpers are available. Do not reference this class from initializers — the
  # parent is resolved when Zeitwerk first loads it.
  class ApplicationController < RivetCms.parent_controller.constantize
    layout "rivet_cms/application"

    before_action :authenticate_rivet_user
    before_action :set_rivet_current_user
    before_action :set_current_organization
    after_action :set_csrf_cookie

    inertia_config version: -> { RivetCms.asset_version }

    inertia_share app_version: RivetCms::VERSION,
                  flash: -> { { notice: flash.notice, alert: flash.alert } },
                  auth: -> {
                    user = Current.user
                    { name: RivetCms.user_name.call(user), email: RivetCms.user_email.call(user) } if user
                  },
                  paths: -> {
                    {
                      root: root_path,
                      content: content_path,
                      media: media_assets_path,
                      content_types: content_types_path,
                      new_content_type: new_content_type_path,
                      components: components_path,
                      new_component: new_component_path,
                      login: RivetCms.login_path,
                      logout: RivetCms.logout_path,
                      logout_method: RivetCms.logout_method
                    }
                  }

    private

    # Inertia (axios) reads the XSRF-TOKEN cookie and sends it back as a header.
    def set_csrf_cookie
      cookies["XSRF-TOKEN"] = form_authenticity_token
    end

    def authenticate_rivet_user
      result = RivetCms.authenticate.call(self)
      return if performed? # the lambda rendered/redirected on its own
      return if result     # truthy => allowed

      deny_rivet_access    # falsy and unhandled => fail closed
    end

    def deny_rivet_access
      if request.inertia?
        head :unauthorized
      elsif RivetCms.login_path.present?
        redirect_to RivetCms.login_path
      else
        render plain: "RivetCms: authentication required.", status: :forbidden
      end
    end

    def set_rivet_current_user
      Current.user = RivetCms.current_user.call(self)
    end

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
