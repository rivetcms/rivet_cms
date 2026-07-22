require 'rails_helper'

module RivetCms
  RSpec.describe "API docs", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    it "renders the API reference page with each content type's endpoints" do
      create(:content_type, name: "Article", slug: "articles", organization: organization)

      get rivet_cms.api_docs_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Api/Index")
      expect(response.body).to include("articles")
    end

    it "downloads a valid OpenAPI 3 spec" do
      ct = create(:content_type, slug: "articles", organization: organization)
      create(:field, field_type: :datetime, key: "starts_at", content_type: ct, organization: organization)

      get rivet_cms.api_openapi_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("attachment")

      spec = JSON.parse(response.body)
      expect(spec["openapi"]).to start_with("3.")
      expect(spec.dig("components", "securitySchemes", "bearerAuth", "scheme")).to eq("bearer")
      expect(spec["paths"]).to include("#{request.base_url}/api/articles")
      starts_at = spec.dig("paths", "#{request.base_url}/api/articles", "get")
      expect(starts_at["parameters"].map { |p| p["name"] }).to include("page", "per_page", "sort")
    end
  end
end
