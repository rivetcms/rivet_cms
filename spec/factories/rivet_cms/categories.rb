FactoryBot.define do
  factory :category, class: "RivetCms::Category" do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    position { 0 }
    system { false }
    organization

    trait :system do
      system { true }
    end

    trait :with_position do
      sequence(:position) { |n| n }
    end
  end
end
