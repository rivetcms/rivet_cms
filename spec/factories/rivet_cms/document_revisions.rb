FactoryBot.define do
  factory :document_revision, class: "RivetCms::DocumentRevision" do
    document
    locale { "en" }
    state { :draft }
    author_name { "System" }

    trait :published do
      state { :published }
      published_at { Time.current }
    end

    trait :archived do
      state { :archived }
    end
  end
end
