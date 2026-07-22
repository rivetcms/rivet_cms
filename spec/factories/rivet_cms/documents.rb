FactoryBot.define do
  factory :document, class: "RivetCms::Document" do
    organization
    content_type { association(:content_type, organization: organization) }
    sequence(:slug) { |n| "document-#{n}" }
  end
end
