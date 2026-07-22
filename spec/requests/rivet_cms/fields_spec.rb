require 'rails_helper'

module RivetCms
  RSpec.describe "Fields", type: :request do
    # Use or create the default org that the controller will use
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, organization: organization) }

    describe "POST /content_types/:content_type_id/fields" do
      it "creates a field" do
        expect {
          post rivet_cms.content_type_fields_path(content_type), params: {
            field: { label: "Title", field_type: "string", width: "full" }
          }
        }.to change(Field, :count).by(1)
      end

      it "creates a component field with cardinality and config" do
        post rivet_cms.content_type_fields_path(content_type), params: {
          field: { label: "Blocks", field_type: "component", min_items: 1, max_items: 5, config: { component_id: "comp_x" } }
        }
        field = Field.last
        expect(field.field_type).to eq("component")
        expect(field.key).to eq("blocks")
        expect(field.min_items).to eq(1)
        expect(field.max_items).to eq(5)
        expect(field.config["component_id"]).to eq("comp_x")
      end
    end

    describe "PATCH /content_types/:content_type_id/fields/:id" do
      it "updates the field" do
        field = create(:field, label: "Old Name", content_type: content_type, organization: content_type.organization)
        patch rivet_cms.content_type_field_path(content_type, field), params: {
          field: { label: "New Name" }
        }
        expect(field.reload.label).to eq("New Name")
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

    describe "component fields" do
      let(:component) { create(:component, organization: organization) }

      it "creates a field on a component" do
        expect {
          post rivet_cms.component_fields_path(component), params: {
            field: { label: "Heading", field_type: "string" }
          }
        }.to change(component.fields, :count).by(1)
        expect(response).to redirect_to(rivet_cms.component_path(component))
      end

      it "updates a component field" do
        field = create(:field, :for_component, component: component, organization: organization)
        patch rivet_cms.component_field_path(component, field), params: { field: { label: "Renamed" } }
        expect(field.reload.label).to eq("Renamed")
      end

      it "updates layout for component fields" do
        f1 = create(:field, :for_component, component: component, organization: organization)
        f2 = create(:field, :for_component, component: component, organization: organization)

        post rivet_cms.update_layout_component_fields_path(component),
             params: { rows: [ [ f2.id ], [ f1.id ] ] }, as: :json

        expect(f2.reload.row).to eq(0)
        expect(f1.reload.row).to eq(1)
      end
    end

    describe "POST /content_types/:content_type_id/fields/update_layout" do
      it "updates field layout with rows" do
        field1 = create(:field, content_type: content_type, organization: content_type.organization)
        field2 = create(:field, content_type: content_type, organization: content_type.organization)
        field3 = create(:field, content_type: content_type, organization: content_type.organization)

        # Reorder: field3 alone, then field1 and field2 paired
        post rivet_cms.update_layout_content_type_fields_path(content_type),
             params: { rows: [ [ field3.id ], [ field1.id, field2.id ] ] },
             as: :json

        expect(response).to redirect_to(rivet_cms.content_type_path(content_type))
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
