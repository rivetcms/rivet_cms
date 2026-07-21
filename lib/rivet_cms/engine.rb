module RivetCms
  class Engine < ::Rails::Engine
    isolate_namespace RivetCms

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Run engine migrations from the host app without requiring
    # `rails rivet_cms:install:migrations`.
    initializer "rivet_cms.append_migrations" do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        unless app.config.paths["db/migrate"].expanded.include?(expanded_path)
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
