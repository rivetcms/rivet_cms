FactoryBot.define do
  factory :component, class: "RivetCms::Component" do
    sequence(:name) { |n| "Component #{n}" }
    sequence(:slug) { |n| "component-#{n}" }
    description { "A component description" }
    repeatable { false }
    category
    organization

    trait :repeatable do
      repeatable { true }
    end

    trait :single do
      repeatable { false }
    end

    trait :without_organization do
      organization { nil }
    end
  end
end
