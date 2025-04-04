require_relative "lib/rivet_cms/version"

Gem::Specification.new do |spec|
  spec.name        = "rivet_cms"
  spec.version     = RivetCms::VERSION
  spec.authors     = [ "Nathan Williams" ]
  spec.email       = [ "nathan@nathan.la" ]
  spec.homepage    = "https://github.com/narch/rivet_cms"
  spec.summary     = "A modern, flexible headless CMS engine for Ruby on Rails"
  spec.description = "Rivet CMS is a powerful headless CMS engine for Ruby on Rails. It provides a flexible content management system with dynamic content types, API-first architecture, and a modern admin interface."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/narch/rivet_cms"
  spec.metadata["changelog_uri"] = "https://github.com/narch/rivet_cms/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 7.1"
  spec.add_dependency "image_processing"
  spec.add_dependency "prefixed_ids"
  spec.add_dependency "kaminari"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "i18n-tasks"
end
