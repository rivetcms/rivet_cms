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

    describe "GET /content_types/:id" do
      it "renders the builder with settings available" do
        content_type = create(:content_type, organization: organization)
        get rivet_cms.content_type_path(content_type)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("ContentTypes/Show")
      end
    end

    describe "DELETE /content_types/:id" do
      it "destroys a content type that has soft-deleted fields" do
        content_type = create(:content_type, organization: organization)
        create(:field, :discarded, content_type: content_type, organization: organization)

        expect {
          delete rivet_cms.content_type_path(content_type)
        }.to change(ContentType, :count).by(-1)
        expect(response).to redirect_to(rivet_cms.content_types_path)
      end
    end
  end
end
