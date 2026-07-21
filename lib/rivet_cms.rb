require "rivet_cms/version"
require "rivet_cms/engine"
require "acts_as_tenant"
require "image_processing"
require "prefixed_ids"
require "kaminari"
require "inertia_rails"

module RivetCms
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
