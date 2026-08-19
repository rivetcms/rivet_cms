module RivetCms
  # Inherits from the host-configured parent controller so host auth filters and
  # helpers are available. Do not reference this class from initializers — the
  # parent is resolved when Zeitwerk first loads it. Admin controllers only:
  # the delivery API inherits DeliveryBaseController, so host filters never
  # reach it.
  class ApplicationController < RivetCms.parent_controller.constantize
    include ResolvesOrganization

    layout "rivet_cms/application"

    # Organization first: built-in authentication scopes its user lookup to it
    before_action :set_current_organization
    before_action :authenticate_rivet_user
    before_action :set_rivet_current_user
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
                      login: effective_login_path,
                      logout: effective_logout_path,
                      logout_method: RivetCms.builtin_auth? ? "delete" : RivetCms.logout_method
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
        next if item.visible && instance_exec(&item.visible) != true
        next if item.requires && !can?(*item.requires)

        path = item.path.respond_to?(:call) ? instance_exec(&item.path) : item.path
        section = sections.find { |s| s[:section] == item.section } ||
                  (sections << { section: item.section, items: [] }).last
        entry = { key: item.key, label: item.label, icon: item.icon, path: path, exact: item.exact }
        badge = nav_badge(item)
        entry[:badge] = badge if badge&.positive?
        section[:items] << entry
      end
      sections
    end

    # A raising badge lambda loses its badge, not the sidebar
    def nav_badge(item)
      return nil unless item.badge

      Integer(instance_exec(&item.badge))
    rescue StandardError => error
      Rails.logger&.error("[RivetCms] nav badge for #{item.key} raised (skipping): #{error.class}: #{error.message}")
      nil
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

    # Trashing something should land back where the delete came from, except
    # when the referer is a page that just died with the trashed record.
    def redirect_after_trash(dead_path, fallback, **flash)
      referer_path = begin
        URI.parse(request.referer.to_s).path
      rescue URI::Error
        nil
      end
      if referer_path == dead_path
        redirect_to fallback, status: :see_other, **flash
      else
        redirect_back fallback_location: fallback, allow_other_host: false, status: :see_other, **flash
      end
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
      return builtin_authenticate if RivetCms.builtin_auth?

      result = RivetCms.authenticate.call(self)
      return if performed? # the lambda rendered/redirected on its own
      return if result     # truthy => allowed

      deny_rivet_access    # falsy and unhandled => fail closed
    end

    def builtin_authenticate
      return if builtin_session_user

      if request.inertia?
        head :unauthorized
      elsif RivetCms::User.where(organization: Current.organization).none?
        redirect_to setup_path # first run: create the owner account
      else
        redirect_to login_path
      end
    end

    def builtin_session_user
      return @builtin_session_user if defined?(@builtin_session_user)

      user = RivetCms::User.where(organization: Current.organization)
                           .find_by(id: session[:rivet_cms_user_id])
      # can_sign_in?: deactivation and a wiped password both end the session.
      # The salt comparison ends every session issued before a password change.
      valid = user&.can_sign_in? &&
              ActiveSupport::SecurityUtils.secure_compare(user.password_salt.to_s, session[:rivet_cms_password_salt].to_s)
      @builtin_session_user = valid ? user : nil
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
      Current.user = RivetCms.builtin_auth? ? builtin_session_user : RivetCms.current_user.call(self)
    end

    def effective_login_path
      RivetCms.builtin_auth? ? login_path : RivetCms.login_path
    end

    def effective_logout_path
      RivetCms.builtin_auth? ? logout_path : RivetCms.logout_path
    end
  end
end
