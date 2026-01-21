FactoryBot.define do
  factory :organization, class: "RivetCms::Organization" do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:domain) { |n| "org#{n}.example.com" }
    subdomain { nil }
    default { false }
    timezone { "UTC" }

    trait :default do
      default { true }
    end

    trait :with_subdomain do
      sequence(:subdomain) { |n| "org#{n}" }
    end
  end
end
