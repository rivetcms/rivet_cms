require "rails_helper"

RSpec.describe RivetCms do
  describe ".asset_version" do
    around do |example|
      had_cached_version = described_class.instance_variable_defined?(:@asset_version)
      cached_version = described_class.instance_variable_get(:@asset_version)
      described_class.remove_instance_variable(:@asset_version) if had_cached_version

      example.run
    ensure
      described_class.remove_instance_variable(:@asset_version) if described_class.instance_variable_defined?(:@asset_version)
      described_class.instance_variable_set(:@asset_version, cached_version) if had_cached_version
    end

    it "includes the JavaScript, stylesheet, and gem version" do
      build_path = RivetCms::Engine.root.join("app/assets/builds")
      asset_digests = %w[rivet_cms.js rivet_cms.css].map do |filename|
        Digest::MD5.file(build_path.join(filename)).hexdigest
      end
      expected = Digest::MD5.hexdigest([ RivetCms::VERSION, *asset_digests ].join(":"))

      expect(described_class.asset_version).to eq(expected)
    end
  end
end
