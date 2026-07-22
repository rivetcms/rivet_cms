FactoryBot.define do
  factory :user, class: "RivetCms::User" do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :member }
    organization

    trait :admin do
      role { :admin }
    end

    trait :owner do
      role { :owner }
    end

    trait :invited do
      invited_at { 1.day.ago }
      accepted_at { nil }
      association :invited_by, factory: :user
    end

    trait :accepted do
      invited_at { 2.days.ago }
      accepted_at { 1.day.ago }
      association :invited_by, factory: :user
    end

    trait :deleted do
      deleted_at { 1.day.ago }
      association :deleted_by, factory: :user
    end
  end
end
