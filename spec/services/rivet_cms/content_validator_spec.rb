require 'rails_helper'

module RivetCms
  RSpec.describe ContentValidator do
    let(:document) { create(:document) }
    let(:content_type) { document.content_type }
    let(:org) { document.organization }
    let(:revision) { create(:document_revision, document: document) }

    def validate
      described_class.new(revision).validate
    end

    it "passes when a required field is present" do
      field = create(:field, :string, required: true, content_type: content_type, organization: org)
      revision.content_values.create!(field: field, string_value: "present")
      expect(validate).to be_valid
    end

    it "fails when a required field is missing" do
      create(:field, :string, required: true, content_type: content_type, organization: org)
      result = validate
      expect(result).not_to be_valid
      expect(result.messages.join).to include("is required")
    end

    it "treats a blank string as missing" do
      field = create(:field, :string, required: true, content_type: content_type, organization: org)
      revision.content_values.create!(field: field, string_value: "")
      expect(validate).not_to be_valid
    end

    it "treats boolean false as present" do
      field = create(:field, :boolean, required: true, content_type: content_type, organization: org)
      revision.content_values.create!(field: field, boolean_value: false)
      expect(validate).to be_valid
    end

    it "enforces max_length from config" do
      field = create(:field, :string, content_type: content_type, organization: org, config: { "max_length" => 3 })
      revision.content_values.create!(field: field, string_value: "toolong")
      expect(validate).not_to be_valid
    end

    it "enforces reference cardinality" do
      create(:field, field_type: :reference, min_items: 1, content_type: content_type, organization: org)
      expect(validate).not_to be_valid
    end

    describe "numeric config" do
      it "enforces integer min/max stored as strings without raising" do
        field = create(:field, :integer, content_type: content_type, organization: org,
                                         config: { "min" => "5", "max" => "10" })
        revision.content_values.create!(field: field, integer_value: 3)
        result = validate
        expect(result).not_to be_valid
        expect(result.messages.join).to include("too small")
      end

      it "enforces decimal min/max" do
        field = create(:field, :decimal, content_type: content_type, organization: org,
                                         config: { "min" => "1", "max" => "5" })
        revision.content_values.create!(field: field, decimal_value: "5.5")
        result = validate
        expect(result).not_to be_valid
        expect(result.messages.join).to include("too large")
      end

      it "accepts a decimal within bounds" do
        field = create(:field, :decimal, content_type: content_type, organization: org,
                                         config: { "min" => 1, "max" => 5 })
        revision.content_values.create!(field: field, decimal_value: "4.75")
        expect(validate).to be_valid
      end
    end

    describe "enumeration" do
      it "accepts a listed choice and rejects an unlisted one" do
        field = create(:field, :enumeration, content_type: content_type, organization: org)
        value = revision.content_values.create!(field: field, string_value: "two")
        expect(validate).to be_valid

        value.update!(string_value: "four")
        result = described_class.new(revision.reload).validate
        expect(result).not_to be_valid
        expect(result.messages.join).to include("is not a valid choice")
      end

      it "allows blank when not required" do
        create(:field, :enumeration, content_type: content_type, organization: org)
        expect(validate).to be_valid
      end
    end

    describe "pattern" do
      def string_value(config, value)
        field = create(:field, :string, content_type: content_type, organization: org, config: config)
        revision.content_values.create!(field: field, string_value: value)
      end

      it "accepts a matching value" do
        string_value({ "pattern" => "\\A[a-z]+@[a-z]+\\.[a-z]+\\z" }, "dev@example.com")
        expect(validate).to be_valid
      end

      it "rejects a non-matching value" do
        string_value({ "pattern" => "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" }, "not-an-email")
        result = validate
        expect(result).not_to be_valid
        expect(result.messages.join).to include("does not match")
      end

      it "treats an invalid pattern as a validation failure, not an exception" do
        field = create(:field, :string, content_type: content_type, organization: org)
        field.update_column(:config, { "pattern" => "([unclosed" })
        revision.content_values.create!(field: field, string_value: "anything")
        expect { validate }.not_to raise_error
        expect(validate).not_to be_valid
      end
    end

    describe "media config" do
      let(:asset) { create(:media_asset, organization: org) }

      def image_value(config)
        field = create(:field, :image, content_type: content_type, organization: org, config: config)
        revision.content_values.create!(field: field, media_asset: asset)
      end

      it "accepts a file whose extension is allowed" do
        image_value("allowed_types" => [ "png", "jpg" ])
        expect(validate).to be_valid
      end

      it "rejects a file whose extension is not allowed" do
        image_value("allowed_types" => [ "gif" ])
        expect(validate).not_to be_valid
        expect(validate.messages.join).to include("disallowed file type")
      end

      it "accepts comma-separated allowed_types from file fields" do
        image_value("allowed_types" => "gif, png")
        expect(validate).to be_valid
      end

      it "enforces max_size_mb" do
        image_value("max_size_mb" => "0.000001")
        expect(validate).not_to be_valid
        expect(validate.messages.join).to include("too large")
      end
    end
  end
end
