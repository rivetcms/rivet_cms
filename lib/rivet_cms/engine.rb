# lib/rivet_cms/engine.rb
require "image_processing"
require "prefixed_ids"
require "kaminari"
require "turbo-rails"
require "stimulus-rails"
require "rivet_cms/routes"

module RivetCms
  class Engine < ::Rails::Engine
    isolate_namespace RivetCms

    # Define tenant-scoped models
    TENANT_SCOPED_MODELS = %w[Component Content ContentType].freeze

    initializer 'rivet_cms.configure_tenant_scoping' do
      ActiveSupport.on_load(:active_record) do
        TENANT_SCOPED_MODELS.each do |model_name|
          model = "RivetCms::#{model_name}".constantize
          model.include(RivetCms::DefaultSite) unless defined?(RivetCmsPro)
        end
      end
    end

    # Configure internationalization before the engine loads
    config.before_configuration do
      config.i18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', 'config', 'locales', '**', '*.yml')]
    end

    # Set up testing and factory configurations
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    def self.add_routes(&block)
      RivetCms::Routes.add_routes(&block)
    end

    def self.append_routes(&block)
      RivetCms::Routes.append_routes(&block)
    end

    def self.draw_routes(&block)
      RivetCms::Routes.draw_routes(&block)
    end
  end
end