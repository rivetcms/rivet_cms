FactoryBot.define do
  factory :field, class: "RivetCms::Field" do
    sequence(:label) { |n| "Field #{n}" }
    sequence(:key) { |n| "field_#{n}" }
    field_type { :string }
    required { false }
    position { 0 }
    width { "full" }
    organization
    content_type
    component { nil }

    trait :required do
      required { true }
    end

    trait :string do
      field_type { :string }
    end

    trait :text do
      field_type { :text }
    end

    trait :rich_text do
      field_type { :rich_text }
    end

    trait :markdown do
      field_type { :markdown }
    end

    trait :integer do
      field_type { :integer }
    end

    trait :decimal do
      field_type { :decimal }
    end

    trait :enumeration do
      field_type { :enumeration }
      config { { "choices" => [ "one", "two", "three" ] } }
    end

    trait :boolean do
      field_type { :boolean }
    end

    trait :image do
      field_type { :image }
    end

    trait :video do
      field_type { :video }
    end

    trait :file do
      field_type { :file }
    end

    trait :half_width do
      width { "half" }
    end

    trait :for_component do
      content_type { nil }
      component
    end

    trait :discarded do
      deleted_at { 1.day.ago }
    end
  end
end
