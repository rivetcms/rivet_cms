require 'rails_helper'

module RivetCms
  RSpec.describe "ContentTypes", type: :request do
    # Use or create the default org that the controller will use
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    describe "GET /content_types" do
      it "returns http success" do
        get rivet_cms.content_types_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /content_types/:id" do
      it "returns http success" do
        content_type = create(:content_type, organization: organization)
        get rivet_cms.content_type_path(content_type)
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /content_types/:id/edit" do
      it "returns http success" do
        content_type = create(:content_type, organization: organization)
        get rivet_cms.edit_content_type_path(content_type)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
