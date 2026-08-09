require 'rails_helper'

module RivetCms
  # Regression for a Sprockets host raising AssetNotFound in production: the
  # engine must register its precompiled bundles for precompilation. Exercises
  # the initializer directly against a Sprockets-shaped config (an Array
  # precompile list) so it does not depend on which pipeline the dummy uses.
  RSpec.describe "Engine asset precompilation" do
    let(:initializer) { RivetCms::Engine.initializers.find { |i| i.name == "rivet_cms.assets" } }

    def app_with(precompile)
      assets = ActiveSupport::OrderedOptions.new
      assets.precompile = precompile
      config = ActiveSupport::OrderedOptions.new
      config.assets = assets
      Struct.new(:config).new(config)
    end

    it "adds the bundles to a Sprockets precompile list" do
      app = app_with([ "application.js" ])
      initializer.run(app)
      expect(app.config.assets.precompile).to include("rivet_cms.js", "rivet_cms.css")
    end

    it "does not duplicate on repeated boots" do
      app = app_with([ "rivet_cms.js", "rivet_cms.css" ])
      initializer.run(app)
      expect(app.config.assets.precompile.count("rivet_cms.js")).to eq(1)
    end

    it "no-ops when there is no Array precompile list (e.g. Propshaft)" do
      assets = ActiveSupport::OrderedOptions.new # precompile stays nil
      config = ActiveSupport::OrderedOptions.new
      config.assets = assets
      app = Struct.new(:config).new(config)
      expect { initializer.run(app) }.not_to raise_error
      expect(app.config.assets.precompile).to be_nil
    end

    it "ships the compiled bundles but not the JS source or the source map" do
      files = Gem::Specification.load(RivetCms::Engine.root.join("rivet_cms.gemspec").to_s).files
      expect(files).to include("app/assets/builds/rivet_cms.js", "app/assets/builds/rivet_cms.css")
      expect(files.grep(%r{\Aapp/javascript/})).to be_empty
      expect(files.grep(/\.map\z/)).to be_empty
    end
  end
end
