require "rivet_cms/version"
require "rivet_cms/engine"
require "image_processing"
require "prefixed_ids"
require "kaminari"
require "inertia_rails"

module RivetCms
  class << self
    # Hard ceiling for library uploads (bytes); hosts can override in an initializer.
    attr_accessor :max_upload_size

    # Host (e.g. "https://cms.example.com") used to build absolute media URLs
    # in the public API. When nil, URLs are relative paths.
    attr_accessor :media_host

    # When true the delivery API allows anonymous reads of published content.
    # When false (default) every request needs an API token. A preview-scoped
    # token is always required to read drafts, regardless of this setting.
    attr_accessor :public_api

    # Authentication is delegated to the host app. See the initializer template
    # (rails g rivet_cms:install) for a full example.
    attr_accessor :parent_controller
    attr_accessor :authenticate
    attr_accessor :current_user
    attr_accessor :user_name
    attr_accessor :user_email
    attr_accessor :login_path
    attr_accessor :logout_path
    attr_accessor :logout_method

    def configure
      yield self
    end

    def warn_unconfigured_authentication!
      return if @auth_warning_logged

      @auth_warning_logged = true
      Rails.logger&.warn(
        "[RivetCms] No authentication configured — the admin UI is open. " \
        "Set RivetCms.configure { |c| c.authenticate = ... } before deploying."
      )
    end

    def reset_auth_warning!
      @auth_warning_logged = false
    end
  end

  self.max_upload_size = 100 * 1024 * 1024
  self.media_host = nil
  self.public_api = false

  self.parent_controller = "ActionController::Base"
  self.login_path = nil
  self.logout_path = nil
  self.logout_method = "delete"

  # authenticate returns truthy to allow the request and falsy to deny it; the
  # engine turns a denial into a redirect to login_path or a 403 (a lambda may
  # also render/redirect itself). Unconfigured: allow in dev/test with a
  # warning, and FAIL CLOSED everywhere else — staging, production, custom envs.
  DEFAULT_AUTHENTICATE = lambda do |_controller|
    if Rails.env.development? || Rails.env.test?
      RivetCms.warn_unconfigured_authentication!
      true
    else
      false
    end
  end
  self.authenticate = DEFAULT_AUTHENTICATE

  self.current_user = ->(_controller) { nil }

  self.user_name = lambda do |user|
    %i[full_name name display_name email email_address].each do |attr|
      next unless user.respond_to?(attr)

      value = user.public_send(attr)
      return value.to_s if value.present?
    end
    nil
  end

  self.user_email = lambda do |user|
    %i[email email_address].each do |attr|
      next unless user.respond_to?(attr)

      value = user.public_send(attr)
      return value.to_s if value.present?
    end
    nil
  end

  # Digest of the precompiled admin assets, used as the Inertia asset version
  # so clients do a full reload when the gem ships a new build. Recomputed each
  # request in development so a rebuild auto-reloads the browser; memoized
  # elsewhere (assets are static at runtime).
  def self.asset_version
    return compute_asset_version if Rails.env.development?

    @asset_version ||= compute_asset_version
  end

  def self.compute_asset_version
    build_path = Engine.root.join("app/assets/builds")
    asset_digests = %w[rivet_cms.js rivet_cms.css].filter_map do |filename|
      asset = build_path.join(filename)
      Digest::MD5.file(asset).hexdigest if asset.exist?
    end

    asset_digests.any? ? Digest::MD5.hexdigest([ VERSION, *asset_digests ].join(":")) : VERSION
  end
end
