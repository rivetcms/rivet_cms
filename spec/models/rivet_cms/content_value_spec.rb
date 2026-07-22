require 'rails_helper'

module RivetCms
  RSpec.describe ContentValue, type: :model do
    let(:document) { create(:document) }
    let(:org) { document.organization }
    let(:content_type) { document.content_type }
    let(:revision) { create(:document_revision, document: document) }

    def value_for(field_type, raw)
      field = create(:field, field_type: field_type, content_type: content_type, organization: org)
      cv = revision.content_values.create!(field: field)
      cv.value = raw
      cv.save!
      cv.reload
    end

    describe "typed storage" do
      it "stores a string in the string column" do
        cv = value_for(:string, "hello")
        expect(cv.string_value).to eq("hello")
        expect(cv.value).to eq("hello")
      end

      it "stores an integer in the integer column" do
        cv = value_for(:integer, "42")
        expect(cv.integer_value).to eq(42)
        expect(cv.value).to eq(42)
      end

      it "leaves a blank integer as nil rather than coercing to zero" do
        cv = value_for(:integer, "")
        expect(cv.integer_value).to be_nil
      end

      it "stores a boolean in the boolean column" do
        cv = value_for(:boolean, "true")
        expect(cv.boolean_value).to be(true)
      end

      it "stores rich text in the text column" do
        cv = value_for(:rich_text, "<p>hi</p>")
        expect(cv.text_value).to eq("<p>hi</p>")
      end

      it "stores a date in the date column" do
        cv = value_for(:date, "2026-08-01")
        expect(cv.date_value).to eq(Date.new(2026, 8, 1))
        expect(cv.value).to eq(Date.new(2026, 8, 1))
      end

      it "stores a datetime in the datetime column" do
        cv = value_for(:datetime, "2026-08-01T14:30")
        expect(cv.datetime_value).to eq(Time.zone.parse("2026-08-01 14:30"))
      end
    end

    describe "uniqueness" do
      it "allows one value per field per owner" do
        field = create(:field, content_type: content_type, organization: org)
        revision.content_values.create!(field: field, string_value: "a")
        dup = revision.content_values.build(field: field, string_value: "b")
        expect(dup).not_to be_valid
      end
    end

    describe "media tenant integrity" do
      it "rejects a media asset from another organization" do
        field = create(:field, :image, content_type: content_type, organization: org)
        value = revision.content_values.build(field: field, media_asset: create(:media_asset))
        expect(value).not_to be_valid
        expect(value.errors[:media_asset]).to be_present
      end

      it "ignores an unknown media asset id instead of erroring" do
        field = create(:field, :image, content_type: content_type, organization: org)
        value = revision.content_values.build(field: field)
        value.value = "999999"
        expect { value.save! }.not_to raise_error
        expect(value.media_asset).to be_nil
      end
    end
  end
end
