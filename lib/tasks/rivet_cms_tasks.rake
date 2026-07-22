require "rivet_cms/seeds"

namespace :rivet_cms do
  desc "Load content-type templates into an organization (TEMPLATES=blog,pages ORG=example.com)"
  task seed: :environment do
    org = RivetCms::Seeds.resolve_organization(ENV["ORG"])
    names = ENV["TEMPLATES"]&.split(",")&.map(&:strip)&.reject(&:empty?)

    RivetCms::Seeds.load!(organization: org, only: names)
    loaded = names || RivetCms::Seeds.available
    puts "Loaded #{loaded.size} template(s) into #{org.name}: #{loaded.join(', ')}"
  end

  desc "List available content-type templates"
  task templates: :environment do
    RivetCms::Seeds.available.each { |name| puts name }
  end
end
