FactoryBot.define do
  factory :component, class: "RivetCms::Component" do
    sequence(:name) { |n| "Component #{n}" }
    sequence(:slug) { |n| "component-#{n}" }
    description { "A component description" }
    category
    organization
  end
end
