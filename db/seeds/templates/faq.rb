# FAQ — frequently asked questions, groupable and orderable.
RivetCms::Seeds.template "faq" do
  content_type "FAQ", slug: "faqs", description: "Frequently asked questions" do
    string    :question, required: true
    rich_text :answer, required: true
    string    :topic, description: "Optional grouping, e.g. Billing or Shipping", width: :half
    integer   :position, label: "Sort order", width: :half
  end
end
