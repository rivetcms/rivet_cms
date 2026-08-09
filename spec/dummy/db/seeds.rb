# Development seeds for the dummy app: bin/rails db:seed

org = RivetCms::Organization.find_or_create_by!(domain: "localhost") do |o|
  o.name = "Development Org"
  o.subdomain = "dev"
end
puts "Organization: #{org.name} (#{org.domain})"

# Built-in auth is the default (plain `bin/dev`): seed a ready admin so you
# land at the login instead of walking the first-run /setup screen.
admin = RivetCms::User.find_or_create_by!(email: "admin@example.com", organization: org) do |u|
  u.name = "Dev Admin"
  u.password = "password"
end
puts "Built-in admin: #{admin.email} / password"

# Host-auth demo (RIVET_HOST_AUTH=1 bin/dev): the dummy app's own User model
host_user = User.find_or_create_by!(email: "dev@example.com") { |u| u.name = "Dev User" }
puts "Host-auth user: #{host_user.email}"

require "rivet_cms/seeds"
RivetCms::Seeds.load!(organization: org)
puts "Loaded content-type templates: #{RivetCms::Seeds.available.join(', ')}"
