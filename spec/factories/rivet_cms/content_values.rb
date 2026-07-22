FactoryBot.define do
  factory :content_value, class: "RivetCms::ContentValue" do
    association :owner, factory: :document_revision
    field { association(:field, content_type: owner.document.content_type, organization: owner.document.organization) }
    string_value { "Test value" }
  end
end
