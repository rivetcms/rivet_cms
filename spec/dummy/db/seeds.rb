# Create a default organization for development
org = RivetCms::Organization.find_or_create_by!(domain: "localhost") do |o|
  o.name = "Development Org"
  o.subdomain = "dev"
end

puts "Created organization: #{org.name} (#{org.domain})"
