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

    it "documents populate and fields on both endpoints" do
      content_type
      doc = spec
      list_names = doc.dig(:paths, "https://cms.test/api/articles", :get, :parameters).map { |p| p[:name] }
      item_names = doc.dig(:paths, "https://cms.test/api/articles/{slug}", :get, :parameters).map { |p| p[:name] }

      expect(list_names).to include("populate", "fields")
      expect(item_names).to include("populate", "fields")
    end

    it "documents a resolvable reference as oneOf shallow or the target schema" do
      target = create(:content_type, name: "Author", slug: "authors", organization: organization)
      create(:field, field_type: :reference, key: "author", max_items: 1,
                     config: { "content_type_id" => target.id.to_s }, content_type: content_type, organization: organization)

      schema = spec.dig(:components, :schemas, "Articles", :properties, :data, :properties)["author"]
      expect(schema[:oneOf]).to include({ "$ref" => "#/components/schemas/Authors" })
    end

    it "falls back to the shallow shape when the reference target is unresolvable" do
      create(:field, field_type: :reference, key: "author", max_items: 1,
                     config: { "content_type_id" => 999_999 }, content_type: content_type, organization: organization)

      schema = spec.dig(:components, :schemas, "Articles", :properties, :data, :properties)["author"]
      expect(schema).to eq({ type: "object", properties: { id: { type: "string" }, slug: { type: "string" } } })
    end
  end
end
