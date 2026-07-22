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

  describe "DEFAULT_AUTHENTICATE" do
    let(:controller) { double("controller") }

    def with_env(name)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(name))
      yield
    ensure
      allow(Rails).to receive(:env).and_call_original
    end

    it "fails closed (returns false) outside development and test" do
      with_env("production") { expect(RivetCms::DEFAULT_AUTHENTICATE.call(controller)).to be(false) }
      with_env("staging") { expect(RivetCms::DEFAULT_AUTHENTICATE.call(controller)).to be(false) }
    end

    it "allows (returns true) and warns once in development and test" do
      described_class.reset_auth_warning!
      expect(Rails.logger).to receive(:warn).once
      expect(RivetCms::DEFAULT_AUTHENTICATE.call(controller)).to be(true)
      RivetCms::DEFAULT_AUTHENTICATE.call(controller)
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
