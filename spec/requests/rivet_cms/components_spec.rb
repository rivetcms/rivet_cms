require 'rails_helper'

module RivetCms
  RSpec.describe "Components", type: :request do
    # Use or create the default org that the controller will use
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    describe "GET /components" do
      it "returns http success" do
        get rivet_cms.components_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /components/new" do
      it "returns http success" do
        get rivet_cms.new_component_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /components/:id/edit" do
      it "returns http success" do
        category = create(:category, organization: organization)
        component = create(:component, organization: organization, category: category)
        get rivet_cms.edit_component_path(component)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
