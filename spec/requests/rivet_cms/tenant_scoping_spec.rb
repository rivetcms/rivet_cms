require 'rails_helper'

module RivetCms
  RSpec.describe "Tenant scoping", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:other_org) { create(:organization) }

    it "does not list another organization's content types" do
      mine = create(:content_type, organization: organization)
      other = create(:content_type, organization: other_org)

      get rivet_cms.content_types_path
      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(other.name)
    end

    it "404s on another organization's content type" do
      organization
      other = create(:content_type, organization: other_org)

      get rivet_cms.content_type_path(other)
      expect(response).to have_http_status(:not_found)
    end

    it "does not list another organization's components" do
      category = create(:category, organization: organization)
      mine = create(:component, organization: organization, category: category)
      other = create(:component, organization: other_org)

      get rivet_cms.components_path
      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(other.name)
    end

    it "404s on another organization's component" do
      organization
      other = create(:component, organization: other_org)

      get rivet_cms.component_path(other)
      expect(response).to have_http_status(:not_found)
    end

    it "404s the public API for another organization's content type slug" do
      RivetCms.public_api = true
      organization
      create(:content_type, slug: "articles", organization: other_org)

      get rivet_cms.content_index_path("articles")
      expect(response).to have_http_status(:not_found)
    end

    it "ignores foreign field ids in layout updates" do
      content_type = create(:content_type, organization: organization)
      mine = create(:field, content_type: content_type, organization: organization)
      foreign = create(:field, content_type: create(:content_type, organization: other_org), organization: other_org)
      original_row = foreign.row

      post rivet_cms.update_layout_content_type_fields_path(content_type),
           params: { rows: [ [ foreign.id ], [ mine.id ] ] }, as: :json

      expect(foreign.reload.row).to eq(original_row)
      expect(mine.reload.row).to eq(1)
    end
  end
end
