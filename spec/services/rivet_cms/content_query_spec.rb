require "rails_helper"

module RivetCms
  RSpec.describe ContentQuery do
    let(:organization) { create(:organization) }
    let(:content_type) { create(:content_type, slug: "events", organization: organization) }
    let!(:title_field) { create(:field, :string, key: "title", content_type: content_type, organization: organization) }
    let!(:starts_field) { create(:field, field_type: :datetime, key: "starts_at", content_type: content_type, organization: organization) }
    let!(:ref_field) { create(:field, field_type: :reference, key: "venue", content_type: content_type, organization: organization) }

    def publish(slug:, starts_at: nil)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft.content_values.create!(field: starts_field, datetime_value: starts_at) if starts_at
      draft.publish!
      document
    end

    it "sorts by a date field key and clamps per_page" do
      publish(slug: "late", starts_at: Time.zone.parse("2026-12-01 10:00"))
      publish(slug: "early", starts_at: Time.zone.parse("2026-08-01 10:00"))

      docs = described_class.new(content_type, sort: "starts_at", per_page: 5000).documents
      expect(docs.map(&:slug)).to eq(%w[early late])
      expect(docs.limit_value).to eq(100)
    end

    it "sorts by an integer field key, entries without the field last in both directions" do
      order_field = create(:field, field_type: :integer, key: "nav_order", content_type: content_type, organization: organization)
      [ [ "second", 2 ], [ "first", 1 ], [ "unordered", nil ] ].each do |slug, value|
        document = create(:document, slug: slug, content_type: content_type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.content_values.create!(field: order_field, integer_value: value) if value
        draft.publish!
      end

      expect(described_class.new(content_type, sort: "nav_order").documents.map(&:slug)).to eq(%w[first second unordered])
      expect(described_class.new(content_type, sort: "-nav_order").documents.map(&:slug)).to eq(%w[second first unordered])
    end

    it "sorts by a string field key case-insensitively, excluding long-text types" do
      body_field = create(:field, field_type: :text, key: "body", content_type: content_type, organization: organization)
      [ [ "banana", "Banana" ], [ "apple", "apple" ] ].each do |slug, title|
        document = create(:document, slug: slug, content_type: content_type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.content_values.create!(field: title_field, string_value: title)
        draft.publish!
      end

      expect(described_class.new(content_type, sort: "title").documents.map(&:slug)).to eq(%w[apple banana])
      expect { described_class.new(content_type, sort: body_field.key).documents }
        .to raise_error(ContentQuery::Error, /unknown sort field/)
    end

    it "raises on an unknown sort field" do
      expect {
        described_class.new(content_type, sort: "bogus").documents
      }.to raise_error(ContentQuery::Error, /unknown sort field/)
    end

    it "filters with symbol bound keys and Time objects" do
      publish(slug: "aug", starts_at: Time.zone.parse("2026-08-15 10:00"))
      publish(slug: "dec", starts_at: Time.zone.parse("2026-12-15 10:00"))

      docs = described_class.new(content_type, filters: { starts_at: { gte: Time.zone.parse("2026-10-01") } }).documents
      expect(docs.map(&:slug)).to eq([ "dec" ])
    end

    it "raises on an unknown filter field or invalid date" do
      expect {
        described_class.new(content_type, filters: { "nope" => { "gte" => "2026-01-01" } }).documents
      }.to raise_error(ContentQuery::Error, /unknown filter field/)

      expect {
        described_class.new(content_type, filters: { "starts_at" => { "gte" => "not a date" } }).documents
      }.to raise_error(ContentQuery::Error, /invalid date/)
    end

    it "resolves populate from :all, arrays, and comma strings identically" do
      expect(described_class.new(content_type, populate: :all).populate_fields).to eq([ ref_field ])
      expect(described_class.new(content_type, populate: [ :venue ]).populate_fields).to eq([ ref_field ])
      expect(described_class.new(content_type, populate: "venue").populate_fields).to eq([ ref_field ])
    end

    it "raises for unknown or non-reference populate keys" do
      expect { described_class.new(content_type, populate: "title").populate_fields }
        .to raise_error(ContentQuery::Error, /cannot populate/)
    end

    it "validates fields and intersects them with populate" do
      query = described_class.new(content_type, populate: :all, fields: [ "title" ])
      expect(query.field_keys).to eq([ "title" ])
      expect(query.populate_fields).to be_empty

      expect { described_class.new(content_type, fields: "bogus").field_keys }
        .to raise_error(ContentQuery::Error, /unknown field/)
    end
  end
end
