FactoryBot.define do
  factory :content_type, class: "RivetCms::ContentType" do
    sequence(:name) { |n| "Content Type #{n}" }
    sequence(:slug) { |n| "content-type-#{n}" }
    description { "A content type description" }
    single { false }
    organization

    trait :single do
      single { true }
    end

    trait :collection do
      single { false }
    end
  end
end
