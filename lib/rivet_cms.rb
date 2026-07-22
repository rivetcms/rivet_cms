require "rivet_cms/version"
require "rivet_cms/engine"
require "rivet_cms/safe_pattern"
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
