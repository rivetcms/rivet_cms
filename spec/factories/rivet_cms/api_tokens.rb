FactoryBot.define do
  factory :api_token, class: "RivetCms::ApiToken" do
    transient do
      raw { SecureRandom.hex(32) }
    end

    sequence(:name) { |n| "Token #{n}" }
    scope { :published }
    organization
    token_digest { RivetCms::ApiToken.digest(raw) }
    token_last4 { raw.last(4) }

    trait :preview do
      scope { :preview }
    end
  end
end
