# Pages — flexible marketing pages assembled from reusable section components.
RivetCms::Seeds.template "pages" do
  category "Layout", system: true
  category "Content", system: true

  component "Hero", category: "Layout", slug: "hero", description: "Full-width banner with a headline and call to action" do
    string :heading, required: true
    text   :subheading
    image  :background_image
    string :cta_label, label: "Button label", width: :half
    string :cta_url,   label: "Button URL",   width: :half
  end

  component "Call to Action", category: "Layout", slug: "call-to-action", description: "Prompt block with a button" do
    string :heading
    text   :body
    string :button_label, width: :half
    string :button_url,   width: :half
  end

  component "SEO", category: "Content", slug: "seo", description: "Search-engine and social sharing metadata" do
    string  :meta_title,       width: :half
    string  :meta_description, width: :half
    image   :og_image,         label: "Social share image"
    boolean :no_index,         label: "Hide from search engines"
  end

  content_type "Page", slug: "pages", description: "Standalone pages such as About, Pricing, or Contact" do
    string    :title, required: true
    component :hero, use: "Hero", max_items: 1
    rich_text :body
    component :call_to_action, use: "Call to Action", max_items: 1
    component :seo, use: "SEO", max_items: 1
  end
end
