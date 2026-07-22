require 'rails_helper'

module RivetCms
  RSpec.describe OpenApiGenerator do
    let(:organization) { create(:organization) }
    let(:content_type) { create(:content_type, name: "Article", slug: "articles", organization: organization) }

    def spec
      described_class.new(organization, base_url: "https://cms.test/api").as_json
    end

    it "describes both endpoints and a bearer security scheme" do
      content_type
      doc = spec
      expect(doc[:openapi]).to start_with("3.")
      expect(doc[:paths].keys).to include("https://cms.test/api/articles", "https://cms.test/api/articles/{slug}")
      expect(doc.dig(:components, :securitySchemes, :bearerAuth, :scheme)).to eq("bearer")
    end

    it "maps field types to a JSON schema for the content type" do
      create(:field, :string, key: "title", content_type: content_type, organization: organization)
      create(:field, field_type: :integer, key: "views", content_type: content_type, organization: organization)
      create(:field, field_type: :datetime, key: "starts_at", content_type: content_type, organization: organization)

      props = spec.dig(:components, :schemas, "Articles", :properties, :data, :properties)
      expect(props["title"]).to eq({ type: "string" })
      expect(props["views"]).to eq({ type: "integer" })
      expect(props["starts_at"]).to eq({ type: "string", format: "date-time" })
    end
  end
end
