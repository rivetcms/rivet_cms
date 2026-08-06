module RivetCms
  class Engine < ::Rails::Engine
    isolate_namespace RivetCms

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # CE webhooks ride the same lifecycle seam host apps use
    initializer "rivet_cms.webhooks" do
      RivetCms::Hooks.on(:publish, key: :rivet_cms_webhooks) { |revision| RivetCms::Webhooks.deliver(:publish, revision) }
    end

    # Host initializers have run by now; a bad webhook entry should stop
    # boot, not silently drop deliveries behind the hook seam's rescue.
    config.after_initialize do
      RivetCms::Webhooks.validate_config!
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
