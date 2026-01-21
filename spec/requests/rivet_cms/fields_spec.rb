require 'rails_helper'

module RivetCms
  RSpec.describe "Fields", type: :request do
    # Use or create the default org that the controller will use
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, organization: organization) }

    describe "GET /content_types/:content_type_id/fields/new" do
      it "returns http success" do
        get rivet_cms.new_content_type_field_path(content_type)
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /content_types/:content_type_id/fields" do
      it "creates a field" do
        expect {
          post rivet_cms.content_type_fields_path(content_type), params: {
            field: { name: "Title", field_type: "string", width: "full" }
          }
        }.to change(Field, :count).by(1)
      end
    end

    describe "GET /content_types/:content_type_id/fields/:id/edit" do
      it "returns http success" do
        field = create(:field, content_type: content_type, organization: content_type.organization)
        get rivet_cms.edit_content_type_field_path(content_type, field)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /content_types/:content_type_id/fields/:id" do
      it "updates the field" do
        field = create(:field, name: "Old Name", content_type: content_type, organization: content_type.organization)
        patch rivet_cms.content_type_field_path(content_type, field), params: {
          field: { name: "New Name" }
        }
        expect(field.reload.name).to eq("New Name")
      end
    end

    describe "DELETE /content_types/:content_type_id/fields/:id" do
      it "soft deletes the field" do
        field = create(:field, content_type: content_type, organization: content_type.organization)
        delete rivet_cms.content_type_field_path(content_type, field)
        expect(field.reload.discarded?).to be true
      end
    end

    describe "PATCH /content_types/:content_type_id/fields/:id/toggle_width" do
      it "toggles field width from full to half" do
        field = create(:field, width: "full", content_type: content_type, organization: content_type.organization)
        patch rivet_cms.toggle_width_content_type_field_path(content_type, field)
        expect(field.reload.width).to eq("half")
      end

      it "toggles field width from half to full" do
        field = create(:field, width: "half", content_type: content_type, organization: content_type.organization)
        patch rivet_cms.toggle_width_content_type_field_path(content_type, field)
        expect(field.reload.width).to eq("full")
      end
    end

    describe "POST /content_types/:content_type_id/fields/update_layout" do
      it "updates field layout with rows" do
        field1 = create(:field, content_type: content_type, organization: content_type.organization)
        field2 = create(:field, content_type: content_type, organization: content_type.organization)
        field3 = create(:field, content_type: content_type, organization: content_type.organization)

        # Reorder: field3 alone, then field1 and field2 paired
        post rivet_cms.update_layout_content_type_fields_path(content_type),
             params: { rows: [[field3.id], [field1.id, field2.id]] },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(field3.reload.row).to eq(0)
        expect(field3.reload.position).to eq(0)
        expect(field1.reload.row).to eq(1)
        expect(field1.reload.position).to eq(0)
        expect(field2.reload.row).to eq(1)
        expect(field2.reload.position).to eq(1)
      end
    end
  end
end
