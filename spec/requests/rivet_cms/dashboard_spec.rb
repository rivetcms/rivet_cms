require 'rails_helper'

module RivetCms
  RSpec.describe "Dashboards", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    describe "GET /" do
      it "returns http success" do
        get rivet_cms.root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dashboard/Show")
      end

      it "includes stats, recent documents, and per-type counts" do
        content_type = create(:content_type, organization: organization, name: "Post")
        create(:document, organization: organization, content_type: content_type, slug: "hello-world")
        create(:api_token, organization: organization)

        get rivet_cms.root_path

        expect(response.body).to include("recent_documents")
        expect(response.body).to include("hello-world")
        expect(response.body).to include("entry_count")
        expect(response.body).to include("base_path")
      end
    end
  end
end
