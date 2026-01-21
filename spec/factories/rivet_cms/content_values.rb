FactoryBot.define do
  factory :content_value, class: "RivetCms::ContentValue" do
    content
    field
    value { association :field_value_string }
  end

  factory :field_value_string, class: "RivetCms::FieldValues::String" do
    value { "Test string value" }
  end

  factory :field_value_text, class: "RivetCms::FieldValues::Text" do
    value { "Test text value with more content" }
  end

  factory :field_value_integer, class: "RivetCms::FieldValues::Integer" do
    value { 42 }
  end

  factory :field_value_boolean, class: "RivetCms::FieldValues::Boolean" do
    value { true }
  end
end
