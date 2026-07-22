# Create a default organization for development
org = RivetCms::Organization.find_or_create_by!(domain: "localhost") do |o|
  o.name = "Development Org"
  o.subdomain = "dev"
end

puts "Created organization: #{org.name} (#{org.domain})"

user = User.find_or_create_by!(email: "dev@example.com") do |u|
  u.name = "Dev User"
end

puts "Created user: #{user.name} (#{user.email})"
