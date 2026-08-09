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

  describe ".configure" do
    it "yields the module for assignment" do
      described_class.configure { |config| config.login_path = "/signin" }
      expect(described_class.login_path).to eq("/signin")
    end
  end

  describe "defaults" do
    it "has delegation-friendly defaults" do
      expect(described_class.parent_controller).to eq("ActionController::Base")
      expect(described_class.login_path).to be_nil
      expect(described_class.logout_path).to be_nil
      expect(described_class.logout_method).to eq("delete")
      expect(described_class.current_user.call(nil)).to be_nil
    end
  end

  describe "authentication mode detection" do
    it "is built-in exactly while authenticate is untouched" do
      RivetCms.authenticate = RivetCms::DEFAULT_AUTHENTICATE
      expect(described_class.builtin_auth?).to be(true)

      RivetCms.authenticate = ->(_c) { true }
      expect(described_class.builtin_auth?).to be(false)

      # An identical-looking lambda is still host mode: identity, not shape
      RivetCms.authenticate = ->(_c) { false }
      expect(described_class.builtin_auth?).to be(false)
    end

    it "the sentinel fails closed if something calls it anyway" do
      expect(RivetCms::DEFAULT_AUTHENTICATE.call(double("controller"))).to be(false)
    end
  end

  describe "user mapping defaults" do
    it "prefers full_name, then name, then email" do
      expect(described_class.user_name.call(Struct.new(:full_name, :name).new("Jane Doe", "jd"))).to eq("Jane Doe")
      expect(described_class.user_name.call(Struct.new(:name).new("jd"))).to eq("jd")
      expect(described_class.user_name.call(Struct.new(:email).new("j@x.com"))).to eq("j@x.com")
      expect(described_class.user_name.call(Object.new)).to be_nil
    end

    it "maps email from email or email_address" do
      expect(described_class.user_email.call(Struct.new(:email).new("j@x.com"))).to eq("j@x.com")
      expect(described_class.user_email.call(Struct.new(:email_address).new("j@y.com"))).to eq("j@y.com")
      expect(described_class.user_email.call(Object.new)).to be_nil
    end
  end
end
