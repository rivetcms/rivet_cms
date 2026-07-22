require 'rails_helper'

module RivetCms
  RSpec.describe Relation, type: :model do
    let(:document) { create(:document) }
    let(:org) { document.organization }
    let(:content_type) { document.content_type }
    let(:revision) { create(:document_revision, document: document) }
    let(:field) { create(:field, field_type: :reference, content_type: content_type, organization: org) }

    it "links to a target document in the same organization" do
      target = create(:document, content_type: content_type, organization: org)
      relation = revision.relations.build(field: field, target_document: target)
      expect(relation).to be_valid
    end

    it "rejects a target document from another organization" do
      target = create(:document)
      relation = revision.relations.build(field: field, target_document: target)
      expect(relation).not_to be_valid
      expect(relation.errors[:target_document]).to be_present
    end
  end
end
