require 'rails_helper'

module RivetCms
  RSpec.describe DocumentRevision, type: :model do
    let(:document) { create(:document) }
    let(:content_type) { document.content_type }
    let(:org) { document.organization }

    it "defaults to the draft state" do
      expect(build(:document_revision).state).to eq("draft")
    end

    describe "#publish!" do
      it "creates a published snapshot and points the document at it" do
        field = create(:field, :string, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        draft.content_values.create!(field: field, string_value: "Hello")

        snapshot = draft.publish!

        expect(snapshot).to be_published
        expect(document.reload.published_revision).to eq(snapshot)
        expect(snapshot.content_values.find_by(field: field).string_value).to eq("Hello")
        expect(draft.reload).to be_draft
      end

      it "keeps the published snapshot unchanged when the draft changes afterward" do
        field = create(:field, :string, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        value = draft.content_values.create!(field: field, string_value: "Original")

        snapshot = draft.publish!
        value.update!(string_value: "Edited")

        expect(snapshot.content_values.find_by(field: field).string_value).to eq("Original")
      end

      it "publishes cleanly when the draft holds values for soft-deleted fields" do
        kept = create(:field, :string, key: "work_email", content_type: content_type, organization: org)
        removed = create(:field, :string, key: "email", content_type: content_type, organization: org)
        removed_ref = create(:field, field_type: :reference, key: "old_ref", content_type: content_type, organization: org)
        target = create(:document, content_type: content_type, organization: org)

        draft = create(:document_revision, document: document, state: :draft)
        draft.content_values.create!(field: kept, string_value: "a@b.co")
        draft.content_values.create!(field: removed, string_value: "stale@old.co")
        draft.relations.create!(field: removed_ref, target_document: target, position: 0)
        removed.discard!
        removed_ref.discard!

        snapshot = draft.publish!

        expect(snapshot.content_values.count).to eq(1)
        expect(snapshot.content_values.first.field_id).to eq(kept.id)
        expect(snapshot.relations.count).to eq(0)
      end

      it "deep-copies relations pointing at the target document" do
        target = create(:document, content_type: content_type, organization: org)
        ref_field = create(:field, field_type: :reference, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        draft.relations.create!(field: ref_field, target_document: target, position: 0)

        snapshot = draft.publish!

        expect(snapshot.relations.first.target_document).to eq(target)
      end

      it "deep-copies nested component instances and their values" do
        component = create(:component, organization: org)
        nested_field = create(:field, :for_component, field_type: :string, component: component, organization: org)
        embed_field = create(:field, field_type: :component, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        instance = draft.component_instances.create!(field: embed_field, component: component, position: 0)
        instance.content_values.create!(field: nested_field, string_value: "Nested")

        snapshot = draft.publish!

        snapshot_instance = snapshot.component_instances.first
        expect(snapshot_instance.component).to eq(component)
        expect(snapshot_instance.content_values.first.string_value).to eq("Nested")
      end

      it "carries the media asset reference through publish" do
        asset = create(:media_asset, organization: org)
        image_field = create(:field, :image, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        draft.content_values.create!(field: image_field, media_asset: asset)

        snapshot = draft.publish!

        expect(snapshot.content_values.find_by(field: image_field).media_asset).to eq(asset)
      end
    end

    describe "authorship" do
      it "accepts any host class as a polymorphic author and copies it on publish" do
        author = User.create!(name: "Jane", email: "jane@example.com")
        draft = create(:document_revision, document: document, state: :draft, author: author, author_name: "Jane")

        snapshot = draft.publish!

        expect(snapshot.author).to eq(author)
        expect(snapshot.author_name).to eq("Jane")
      end

      it "keeps the cached author name when the host user is deleted" do
        author = User.create!(name: "Jane", email: "jane@example.com")
        draft = create(:document_revision, document: document, state: :draft, author: author, author_name: "Jane")
        author.destroy!

        expect(draft.reload.author).to be_nil
        expect(draft.author_name).to eq("Jane")
      end
    end

    describe "publish validation" do
      it "refuses to publish when a required field is missing and leaves the document unpublished" do
        create(:field, :string, required: true, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)

        expect { draft.publish! }.to raise_error(RivetCms::ContentInvalidError)
        expect(document.reload.published_revision).to be_nil
      end
    end

    describe "immutability" do
      it "raises when updating a value owned by a published revision" do
        field = create(:field, :string, content_type: content_type, organization: org)
        draft = create(:document_revision, document: document, state: :draft)
        draft.content_values.create!(field: field, string_value: "x")
        snapshot = draft.publish!

        value = snapshot.content_values.first
        expect { value.update!(string_value: "y") }.to raise_error(RivetCms::RevisionImmutableError)
      end
    end
  end
end
