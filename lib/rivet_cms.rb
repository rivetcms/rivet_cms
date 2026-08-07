require "rivet_cms/version"
require "rivet_cms/engine"
require "rivet_cms/safe_pattern"
require "rivet_cms/hooks"
require "rivet_cms/access_check"
require "image_processing"
require "prefixed_ids"
require "kaminari"
require "inertia_rails"

module RivetCms
  class << self
    # Hard ceiling for library uploads (bytes); hosts can override in an initializer.
    attr_accessor :max_upload_size

    # MIME types the media library accepts, checked against the sniffed type,
    # not the client-declared one. nil disables the check. SVG is excluded by
    # default because scripted SVGs are an XSS vector; hosts that trust their
    # editors can append "image/svg+xml".
    attr_accessor :allowed_media_types

    # Host (e.g. "https://cms.example.com") used to build absolute media URLs
    # in the public API. When nil, URLs are relative paths.
    attr_accessor :media_host

    # Basic webhook endpoints: [{ url: "https://...", events: %w[entry.published] }].
    # events is optional (defaults to all). Delivered by WebhookDeliveryJob;
    # no signing or retries.
    attr_accessor :webhooks

    # Subscribe to a lifecycle event; see RivetCms::Hooks for the event list
    # and the key: contract for reload-safe registration.
    #   RivetCms.on(:publish) { |revision| ... }
    def on(event, callable = nil, key: nil, &block)
      Hooks.on(event, callable, key: key, &block)
    end

    # When true the delivery API allows anonymous reads of published content.
    # When false (default) every request needs an API token. A preview-scoped
    # token is always required to read drafts, regardless of this setting.
    attr_accessor :public_api

    # How many superseded published revisions to keep per document. The
    # default :all never deletes anything: pruning is something a host opts
    # into, because unbounded storage is a visible problem you can fix later
    # and deleted content is not. Set an integer to prune on publish. The
    # current published revision and the working draft are never pruned.
    attr_reader :revision_retention

    # Validated at assignment: a bad value here would otherwise surface as a
    # failed publish, or worse, silently mean 0 and destroy history.
    def revision_retention=(value)
      @revision_retention = normalize_retention(value)
    end

    # Retention for one document. Override to vary by organization or content
    # type; the scalar config is the default resolver.
    def retention_for(_document)
      revision_retention
    end

    # What the pruner actually reads: an override is validated the same way
    # the config setter is, so a bad override cannot silently destroy history.
    def normalized_retention_for(document)
      normalize_retention(retention_for(document))
    end

    # Authorization seam: receives one RivetCms::AccessCheck and returns a
    # boolean; default allow. check.action is :read, :write, :publish, or
    # :delete; check.resource is a coarse domain (:content, :schema, :media,
    # :api). The vocabulary grows over time, so policies should allowlist
    # known pairs and deny anything unrecognized. A raising policy denies
    # (fail closed) and logs. Governs the admin UI only; the delivery API
    # is token-gated separately.
    attr_accessor :can

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

    # Ruby content helpers — read CMS content directly from host-app code with
    # the same semantics and options as the delivery API (sort, date filters,
    # pagination, populate, fields, preview).

    # Published entries of a content type. Options mirror the API's list
    # params; populate accepts an array of keys or :all.
    def entries(type_slug, organization: nil, **options)
      content_type = find_content_type!(type_slug, organization)
      query = ContentQuery.new(content_type, **options)
      populate = query.populate_fields

      page = query.documents
      revisions = page.map(&:published_revision)
      preload = RevisionPreloader.new(revisions, populate_fields: populate)

      wrapped = revisions.map do |revision|
        Entry.new(RevisionSerializer.new(revision, fields: query.field_keys, populate: populate, preload: preload).as_json)
      end
      EntryCollection.new(wrapped, page: page.current_page, per_page: page.limit_value,
                                   total: page.total_count, total_pages: page.total_pages)
    end

    # One entry by slug, or nil. preview: true serves the draft when present
    # (Ruby callers are trusted host code — no token gate).
    def entry(type_slug, entry_slug, organization: nil, preview: false, populate: nil, fields: nil)
      content_type = find_content_type!(type_slug, organization)
      document = content_type.documents.find_by(slug: entry_slug)
      serialize_document(content_type, document, preview: preview, populate: populate, fields: fields)
    end

    # The one entry of a single-type content type, or nil.
    def single(type_slug, organization: nil, preview: false, populate: nil, fields: nil)
      content_type = find_content_type!(type_slug, organization)
      document = content_type.documents.find_by(singleton_key: "singleton") || content_type.documents.first
      serialize_document(content_type, document, preview: preview, populate: populate, fields: fields)
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

    private

    # Values above this are a misconfiguration, not a retention policy, and a
    # large enough offset makes the prune query fail at publish time.
    MAX_RETENTION = 1_000_000

    def normalize_retention(value)
      return :all if value == :all || (value.to_s.casecmp("all").zero? rescue false)
      # Compare the class directly: ActiveSupport::Duration answers both is_a?
      # and instance_of? for Integer, so 90.days would otherwise slip through
      # and silently mean 7,776,000 revisions.
      return value if value.class == Integer && !value.negative? && value <= MAX_RETENTION
      # Base 10 explicitly: Integer("0010") would otherwise read as octal
      return Integer(value, 10) if value.is_a?(String) && value.match?(/\A\d+\z/) && Integer(value, 10) <= MAX_RETENTION

      raise ArgumentError,
            "RivetCms.revision_retention must be :all or an Integer between 0 and #{MAX_RETENTION}, " \
            "got #{value.inspect}. Time-based retention is not supported."
    end

    def find_content_type!(type_slug, organization)
      org = organization || Current.organization ||
            Organization.find_by(default: true) || Organization.first
      raise ContentQuery::Error, "no organization available" if org.nil?

      org.content_types.find_by(slug: type_slug.to_s) ||
        raise(ContentQuery::Error, "unknown content type: #{type_slug}")
    end

    def serialize_document(content_type, document, preview:, populate:, fields:)
      return nil if document.nil?

      revision = preview ? (document.draft_revision || document.published_revision) : document.published_revision
      return nil if revision.nil?

      query = ContentQuery.new(content_type, populate: populate, fields: fields)
      populate_fields = query.populate_fields
      preload = RevisionPreloader.new([ revision ], populate_fields: populate_fields, preview: preview)
      Entry.new(RevisionSerializer.new(revision, fields: query.field_keys, populate: populate_fields,
                                                 preview: preview, preload: preload).as_json)
    end
  end

  self.max_upload_size = 100 * 1024 * 1024
  self.allowed_media_types = %w[
    image/png image/jpeg image/gif image/webp image/avif
    video/mp4 video/webm video/quicktime
    audio/mpeg audio/wav audio/ogg
    application/pdf application/zip
    text/plain text/csv
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ]
  self.media_host = nil
  self.public_api = false
  self.webhooks = []
  self.revision_retention = :all

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

  self.can = ->(_check) { true }

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
