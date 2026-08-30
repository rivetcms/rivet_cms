require_relative "lib/rivet_cms/version"

Gem::Specification.new do |spec|
  spec.name        = "rivet_cms"
  spec.version     = RivetCms::VERSION
  spec.authors     = [ "narch" ]
  spec.email       = [ "narch@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/rivetcms/rivetcms"
  spec.summary     = "A headless CMS for Rails applications"
  spec.description = "RivetCms is a headless CMS Rails engine, similar to Strapi, that provides content management functionality for Rails applications."
  spec.license     = "LGPL-3.0-or-later"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = "https://github.com/rivetcms/rivetcms"
  spec.metadata["changelog_uri"] = "https://github.com/rivetcms/rivetcms/blob/main/CHANGELOG.md"

  # Ship the precompiled admin bundle, not its source: app/javascript and the
  # source map are build inputs the runtime never loads, so they only bloat
  # the gem and expose source. The runtime needs app/assets/builds/*.{js,css}.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "COPYING", "COPYING.LESSER", "CHANGELOG.md", "Rakefile", "README.md"]
      .reject { |f| f == "app/javascript" || f.start_with?("app/javascript/") || f.end_with?(".map") }
      .select { |f| File.file?(f) }
  end

  spec.add_dependency "rails", ">= 7.2", "< 9"
  spec.add_dependency "bcrypt", "~> 3.1.7"
  spec.add_dependency "image_processing", "~> 1.14"
  # Declared directly, not left transitive through image_processing: the media
  # library generates variants with the vips backend, so it is a first-class
  # runtime requirement. (The libvips system binary stays optional; missing it
  # degrades to a file-type icon.)
  spec.add_dependency "ruby-vips", "~> 2.0"
  spec.add_dependency "prefixed_ids", "~> 1.8"
  spec.add_dependency "kaminari", "~> 1.2"
  spec.add_dependency "inertia_rails", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 8.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
end
