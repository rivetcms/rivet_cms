require 'rails_helper'

module RivetCms
  RSpec.describe "Content API", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }
    let(:title_field) { create(:field, :string, key: "title", content_type: content_type, organization: organization) }

    def publish_document(slug:, title:)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft.content_values.create!(field: title_field, string_value: title)
      draft.publish!
      document
    end

    it "lists published documents" do
      publish_document(slug: "first", title: "First")
      get rivet_cms.content_index_path("articles")

      body = JSON.parse(response.body)
      expect(body.map { |d| d["slug"] }).to include("first")
      expect(body.first.dig("data", "title")).to eq("First")
    end

    it "shows a single published document" do
      publish_document(slug: "hello", title: "Hello")
      get rivet_cms.content_show_path("articles", "hello")

      body = JSON.parse(response.body)
      expect(body["slug"]).to eq("hello")
      expect(body.dig("data", "title")).to eq("Hello")
    end

    it "returns 404 for a document without a published revision" do
      title_field
      create(:document, slug: "draft-only", content_type: content_type, organization: organization)
      get rivet_cms.content_show_path("articles", "draft-only")

      expect(response).to have_http_status(:not_found)
    end
  end
end
