require 'rails_helper'

module RivetCms
  RSpec.describe ContentValue, type: :model do
    describe "validations" do
      it "requires content" do
        cv = ContentValue.new(content: nil)
        cv.valid?
        expect(cv.errors[:content]).to include("can't be blank")
      end

      it "requires field" do
        cv = ContentValue.new(field: nil)
        cv.valid?
        expect(cv.errors[:field]).to include("can't be blank")
      end

      it "requires value" do
        cv = ContentValue.new(value: nil)
        cv.valid?
        expect(cv.errors[:value]).to include("can't be blank")
      end
    end

    describe ".value_class_for" do
      it "maps string to FieldValues::String" do
        expect(ContentValue.value_class_for("string")).to eq(FieldValues::String)
      end

      it "maps text to FieldValues::Text" do
        expect(ContentValue.value_class_for("text")).to eq(FieldValues::Text)
      end

      it "maps rich_text to FieldValues::Text" do
        expect(ContentValue.value_class_for("rich_text")).to eq(FieldValues::Text)
      end

      it "maps markdown to FieldValues::Text" do
        expect(ContentValue.value_class_for("markdown")).to eq(FieldValues::Text)
      end

      it "maps integer to FieldValues::Integer" do
        expect(ContentValue.value_class_for("integer")).to eq(FieldValues::Integer)
      end

      it "maps boolean to FieldValues::Boolean" do
        expect(ContentValue.value_class_for("boolean")).to eq(FieldValues::Boolean)
      end

      it "maps image to FieldValues::Attachment" do
        expect(ContentValue.value_class_for("image")).to eq(FieldValues::Attachment)
      end

      it "maps video to FieldValues::Attachment" do
        expect(ContentValue.value_class_for("video")).to eq(FieldValues::Attachment)
      end

      it "maps file to FieldValues::Attachment" do
        expect(ContentValue.value_class_for("file")).to eq(FieldValues::Attachment)
      end

      it "raises for unsupported types" do
        expect { ContentValue.value_class_for("unknown") }.to raise_error(ArgumentError)
      end
    end

    describe ".set_value" do
      let(:org) { create(:organization) }
      let(:content_type) { create(:content_type, organization: org) }
      let(:content) { create(:content, content_type: content_type, organization: org) }

      it "creates a string value" do
        field = create(:field, :string, content_type: content_type, organization: org)
        cv = ContentValue.set_value(content, field, "Hello World")

        expect(cv).to be_persisted
        expect(cv.field_value).to eq("Hello World")
      end

      it "creates an integer value" do
        field = create(:field, :integer, content_type: content_type, organization: org)
        cv = ContentValue.set_value(content, field, "42")

        expect(cv).to be_persisted
        expect(cv.field_value).to eq(42)
      end

      it "creates a boolean value" do
        field = create(:field, :boolean, content_type: content_type, organization: org)
        cv = ContentValue.set_value(content, field, "true")

        expect(cv).to be_persisted
        expect(cv.field_value).to eq(true)
      end

      it "updates existing value" do
        field = create(:field, :string, content_type: content_type, organization: org)
        cv1 = ContentValue.set_value(content, field, "First")
        cv2 = ContentValue.set_value(content, field, "Second")

        expect(cv1.id).to eq(cv2.id)
        expect(cv2.field_value).to eq("Second")
      end
    end

    describe "#field_value" do
      it "returns the value from the associated value object" do
        string_value = FieldValues::String.create!(value: "Test")
        content_type = create(:content_type)
        field = create(:field, content_type: content_type, organization: content_type.organization)
        content = create(:content, content_type: content_type, organization: content_type.organization)
        cv = ContentValue.create!(content: content, field: field, value: string_value)

        expect(cv.field_value).to eq("Test")
      end

      it "sanitizes HTML for rich_text fields" do
        text_value = FieldValues::Text.create!(value: "<script>alert('xss')</script><p>Safe</p>")
        content_type = create(:content_type)
        field = create(:field, :rich_text, content_type: content_type, organization: content_type.organization)
        content = create(:content, content_type: content_type, organization: content_type.organization)
        cv = ContentValue.create!(content: content, field: field, value: text_value)

        expect(cv.field_value).not_to include("<script>")
        expect(cv.field_value).to include("<p>Safe</p>")
      end
    end
  end
end
