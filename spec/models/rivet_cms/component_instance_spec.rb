require 'rails_helper'

module RivetCms
  RSpec.describe ComponentInstance, type: :model do
    let(:document) { create(:document) }
    let(:org) { document.organization }
    let(:content_type) { document.content_type }
    let(:revision) { create(:document_revision, document: document) }
    let(:field) { create(:field, field_type: :component, content_type: content_type, organization: org) }

    it "embeds a component from the same organization" do
      component = create(:component, organization: org)
      instance = revision.component_instances.build(field: field, component: component)
      expect(instance).to be_valid
    end

    it "rejects a component from another organization" do
      component = create(:component)
      instance = revision.component_instances.build(field: field, component: component)
      expect(instance).not_to be_valid
      expect(instance.errors[:component]).to be_present
    end
  end
end
