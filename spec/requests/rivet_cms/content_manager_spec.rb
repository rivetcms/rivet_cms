require 'rails_helper'

module RivetCms
  RSpec.describe "Content Manager", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    it "renders the content manager home" do
      create(:content_type, organization: organization)
      get rivet_cms.content_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ContentManager/Index")
    end
  end
end
