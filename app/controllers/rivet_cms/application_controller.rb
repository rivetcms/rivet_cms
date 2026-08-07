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
                  nav: -> { navigation_props },
                  media_accept: -> { RivetCms.allowed_media_types&.join(",") },
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
                      content_types_trash: trash_content_types_path,
                      components: components_path,
                      new_component: new_component_path,
                      api_tokens: api_tokens_path,
                      api_docs: api_docs_path,
                      login: RivetCms.login_path,
                      logout: RivetCms.logout_path,
                      logout_method: RivetCms.logout_method
                    }
                  }

    rescue_from RivetCms::AccessDenied, with: :deny_authorization

    private

    # Sidebar from the Navigation registry: items a user cannot reach are
    # dropped here, so hiding and denying share one source of truth. Sections
    # appear where their lowest-position item falls.
    def navigation_props
      sections = []
      RivetCms::Navigation.items.each do |item|
        next if item.requires && !can?(*item.requires)

        path = item.path.respond_to?(:call) ? instance_exec(&item.path) : item.path
        section = sections.find { |s| s[:section] == item.section } ||
                  (sections << { section: item.section, items: [] }).last
        section[:items] << { key: item.key, label: item.label, icon: item.icon, path: path, exact: item.exact }
      end
      sections
    end

    # Fails closed: a raising policy denies and logs rather than 500ing the admin
    def can?(action, resource, record: nil)
      check = RivetCms::AccessCheck.new(
        user: Current.user, action: action, resource: resource,
        organization: Current.organization, record: record
      )
      RivetCms.can.call(check) == true
    rescue Exception => error
      Rails.logger&.error("[RivetCms] can policy raised (denying): #{error.class}: #{error.message}")
      false
    end

    def authorize!(action, resource, record: nil)
      raise RivetCms::AccessDenied, "#{action} #{resource}" unless can?(action, resource, record: record)
    end

    # List surfaces must not show what a record's own page would refuse, so
    # every list filters through the record phase. Filtering happens after
    # pagination, so a page can come up short; stat counts stay aggregates.
    def permitted(records, action, resource)
      records.select { |record| can?(action, resource, record: record) }
    end

    # Cross-type entry lists check the entry and its type, so denying a type
    # hides its entries everywhere the type itself is hidden
    def permitted_documents(documents)
      permitted(documents, :read, :content)
        .select { |document| can?(:read, :content, record: document.content_type) }
    end

    # Emits onto the :audit stream; call after a mutation succeeded
    def audit(action, subject, **metadata)
      RivetCms::Audit.record(action, subject: subject, actor: Current.user,
                             organization: Current.organization, metadata: metadata)
    end

    def deny_authorization
      message = "You do not have permission to do that"
      # Inertia visits redirect (the client follows and shows the flash).
      # Everything else that is not a plain browser page load — API clients,
      # axios calls whose Accept header Rails reads as browser-like, any
      # non-GET — must get a real 403 so failures surface as failures.
      if !request.inertia? && (request.format.json? || request.xhr? || !request.get?)
        render json: { errors: [ message ] }, status: :forbidden
      else
        # Redirecting to the page we just denied would loop, so only trust a
        # referer that points somewhere else; the dashboard is always reachable.
        referer_path = URI.parse(request.referer.to_s).path rescue nil
        if referer_path.present? && referer_path != request.path
          redirect_back fallback_location: root_path, allow_other_host: false,
                        status: (request.get? ? :found : :see_other), alert: message
        else
          redirect_to root_path, status: (request.get? ? :found : :see_other), alert: message
        end
      end
    end

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
