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
  end
  self.max_upload_size = 100 * 1024 * 1024
  self.media_host = nil

  # Digest of the precompiled admin assets, used as the Inertia asset version
  # so clients do a full reload when the gem ships a new build.
  def self.asset_version
    @asset_version ||= begin
      build_path = Engine.root.join("app/assets/builds")
      asset_digests = %w[rivet_cms.js rivet_cms.css].filter_map do |filename|
        asset = build_path.join(filename)
        Digest::MD5.file(asset).hexdigest if asset.exist?
      end

      asset_digests.any? ? Digest::MD5.hexdigest([ VERSION, *asset_digests ].join(":")) : VERSION
    end
  end
end
