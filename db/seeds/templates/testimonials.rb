# Testimonials — customer quotes and social proof.
RivetCms::Seeds.template "testimonials" do
  content_type "Testimonial", slug: "testimonials", description: "Customer quotes and reviews" do
    text    :quote, required: true
    string  :author_name, required: true, width: :half
    string  :author_role, label: "Role", width: :half
    string  :company, width: :half
    image   :avatar, width: :half
    integer :rating, description: "1 to 5 stars", config: { "min" => 1, "max" => 5 }
  end
end
