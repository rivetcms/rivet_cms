FactoryBot.define do
  factory :content, class: "RivetCms::Content" do
    sequence(:slug) { |n| "content-#{n}" }
    status { :draft }
    organization
    content_type

    trait :draft do
      status { :draft }
    end

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :archived do
      status { :archived }
      unpublished_at { Time.current }
    end
  end
end
