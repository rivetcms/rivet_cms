require_relative "lib/rivet_cms/version"

Gem::Specification.new do |spec|
  spec.name        = "rivet_cms"
  spec.version     = RivetCms::VERSION
  spec.authors     = [ "narch" ]
  spec.email       = [ "narch@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/narch/rivet_cms"
  spec.summary     = "A headless CMS for Rails applications"
  spec.description = "RivetCms is a headless CMS Rails engine, similar to Strapi, that provides content management functionality for Rails applications."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/narch/rivet_cms"
  spec.metadata["changelog_uri"] = "https://github.com/narch/rivet_cms/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.2"
  spec.add_dependency "bcrypt", "~> 3.1.7"
  spec.add_dependency "image_processing", "~> 1.14"
  spec.add_dependency "prefixed_ids", "~> 1.8"
  spec.add_dependency "kaminari", "~> 1.2"
  spec.add_dependency "inertia_rails", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
end
