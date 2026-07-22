# Site settings — a single global record for site-wide values, plus a repeatable
# social-link component. Demonstrates a single-type content type.
RivetCms::Seeds.template "site_settings" do
  category "Global", system: true

  component "Social Link", category: "Global", slug: "social-link", description: "One social network profile" do
    string :platform, width: :half
    string :url,      width: :half
  end

  content_type "Site Settings", slug: "site-settings", single: true, description: "Global values shared across the whole site" do
    string    :site_name, required: true
    string    :tagline
    image     :logo,    width: :half
    image     :favicon, width: :half
    text      :description
    component :social_links, use: "Social Link"
    string    :contact_email, width: :half, config: { "pattern" => "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" }
    string    :contact_phone, width: :half
    text      :footer_text
  end
end
