require 'rails_helper'

module RivetCms
  RSpec.describe RevisionPruner do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, organization: organization) }
    let(:field) { create(:field, :string, key: "title", content_type: content_type, organization: organization) }
    let(:document) { create(:document, content_type: content_type, organization: organization) }

    around do |example|
      original = RivetCms.revision_retention
      example.run
    ensure
      RivetCms.revision_retention = original
    end

    def draft
      @draft ||= begin
        revision = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: revision)
        revision
      end
    end

    def publish(title)
      value = draft.content_values.find_or_initialize_by(field: field)
      value.update!(string_value: title)
      draft.publish!
    end

    it "prunes superseded published revisions when retention is 0" do
      RivetCms.revision_retention = 0
      publish("one")
      publish("two")
      publish("three")

      expect(document.reload.revisions.published.count).to eq(1)
      expect(document.published_revision.content_values.first.string_value).to eq("three")
      expect(document.draft_revision).to eq(draft)
    end

    it "keeps everything by default" do
      publish("one")
      publish("two")
      publish("three")

      expect(document.reload.revisions.published.count).to eq(3)
    end

    it "keeps the configured number of superseded snapshots" do
      RivetCms.revision_retention = 1

      publish("one")
      publish("two")
      publish("three")

      titles = document.reload.revisions.published.ordered.map { |revision| revision.content_values.first&.string_value }
      expect(titles).to eq([ "three", "two" ])
    end

    it "never prunes the current published revision or the draft" do
      RivetCms.revision_retention = 0
      publish("one")
      publish("two")
      live = publish("three")

      expect(DocumentRevision.exists?(live.id)).to be true
      expect(document.reload.published_revision_id).to eq(live.id)
      expect(DocumentRevision.exists?(draft.id)).to be true
      expect(document.revisions.count).to eq(2) # the draft and the live snapshot
    end

    it "breaks created_at ties by id so the newer superseded snapshot survives" do
      RivetCms.revision_retention = :all
      publish("one")
      publish("two")
      publish("three")

      at = 1.day.ago
      document.reload.revisions.published.update_all(created_at: at, published_at: at)
      live_id = document.published_revision_id
      superseded = document.revisions.published.where.not(id: live_id).order(:id).pluck(:id)
      expect(superseded.size).to eq(2)

      RivetCms.revision_retention = 1
      described_class.new(document.reload).prune!

      expect(DocumentRevision.exists?(superseded.last)).to be true  # newer kept
      expect(DocumentRevision.exists?(superseded.first)).to be false # older pruned
    end

    it "does not count a destroy that a callback halted" do
      RivetCms.revision_retention = :all
      publish("one")
      publish("two")
      publish("three")

      RivetCms.revision_retention = 0
      allow_any_instance_of(DocumentRevision).to receive(:destroy).and_return(false)

      expect(described_class.new(document.reload).prune!).to eq(0)
      expect(document.reload.revisions.published.count).to eq(3)
    end

    it "never prunes archived revisions" do
      RivetCms.revision_retention = 0
      archived = document.revisions.create!(state: :archived, author_name: "T")
      publish("one")
      publish("two")

      expect(DocumentRevision.exists?(archived.id)).to be true
    end

    it "destroys the pruned revisions' values so storage is reclaimed" do
      RivetCms.revision_retention = 0
      publish("one")
      superseded_value_ids = document.reload.published_revision.content_values.pluck(:id)

      publish("two")

      expect(ContentValue.where(id: superseded_value_ids)).to be_empty
    end

    it "leaves other documents alone" do
      RivetCms.revision_retention = 0
      other = create(:document, content_type: content_type, organization: organization)
      other_draft = create(:document_revision, document: other, state: :draft)
      other.update!(draft_revision: other_draft)
      other_published = other_draft.publish!

      publish("one")
      publish("two")

      expect(DocumentRevision.exists?(other_published.id)).to be true
    end

    describe "misconfiguration" do
      it "rejects values that would silently destroy or break publishing" do
        [ "all-of-them", nil, true, 90.days, -1, 2.7, :ALL_CAPS_TYPO ].each do |bad|
          expect { RivetCms.revision_retention = bad }
            .to raise_error(ArgumentError, /must be :all or an Integer/), "expected #{bad.inspect} to be rejected"
        end
      end

      it "reads numeric strings in base 10, not octal" do
        RivetCms.revision_retention = "010"
        expect(RivetCms.revision_retention).to eq(10)
      end

      it "rejects a Duration even when it is below the ceiling" do
        expect { RivetCms.revision_retention = 5.minutes }
          .to raise_error(ArgumentError, /must be :all or an Integer/)
      end

      it "enforces the ceiling on every path" do
        RivetCms.revision_retention = 1_000_000
        expect(RivetCms.revision_retention).to eq(1_000_000)

        expect { RivetCms.revision_retention = 1_000_001 }.to raise_error(ArgumentError)
        expect { RivetCms.revision_retention = "1000001" }.to raise_error(ArgumentError)

        allow(RivetCms).to receive(:retention_for).and_return(2_000_000)
        expect { described_class.new(document).prune! }.to raise_error(ArgumentError)
      end

      it "accepts the documented spellings" do
        RivetCms.revision_retention = "all"
        expect(RivetCms.revision_retention).to eq(:all)
        RivetCms.revision_retention = "5"
        expect(RivetCms.revision_retention).to eq(5)
        RivetCms.revision_retention = :all
        expect(RivetCms.revision_retention).to eq(:all)
      end
    end

    it "skips pruning when nothing is published, keeping the history intact" do
      RivetCms.revision_retention = :all
      publish("one")
      publish("two")
      # Detach without deleting: the guard, not a nil locale lookup, is what
      # has to stop the prune here.
      document.reload.update!(published_revision: nil)
      expect(document.revisions.published.count).to eq(2)

      RivetCms.revision_retention = 0
      described_class.new(document.reload).prune!

      expect(document.reload.revisions.published.count).to eq(2)
    end

    it "does not prune from a stale document that missed a concurrent publish" do
      # Retention :all while publishing means the stale pointer still exists,
      # so the DB re-read is what protects the live revision, not a nil lookup.
      RivetCms.revision_retention = :all
      publish("one")
      stale = Document.find(document.id)
      publish("two")
      live_id = document.reload.published_revision_id
      expect(DocumentRevision.exists?(stale.published_revision_id)).to be true

      RivetCms.revision_retention = 0
      described_class.new(stale).prune!

      expect(DocumentRevision.exists?(live_id)).to be true
      expect(document.reload.published_revision_id).to eq(live_id)
    end

    it "keeps a non-live locale's newest snapshot but still prunes its older ones" do
      RivetCms.revision_retention = 0
      publish("en one")
      older_fr = document.revisions.create!(state: :published, locale: "fr", author_name: "T", published_at: 2.days.ago, created_at: 2.days.ago)
      newest_fr = document.revisions.create!(state: :published, locale: "fr", author_name: "T", published_at: 1.day.ago, created_at: 1.day.ago)

      publish("en two")

      expect(DocumentRevision.exists?(newest_fr.id)).to be true
      expect(DocumentRevision.exists?(older_fr.id)).to be false
    end

    it "does not destroy the snapshot a rollback republished from" do
      RivetCms.revision_retention = :all
      first = publish("one")
      publish("two")
      publish("three")

      RivetCms.revision_retention = 0
      republished = first.reload.publish!

      expect(DocumentRevision.exists?(first.id)).to be true
      expect(document.reload.published_revision_id).to eq(republished.id)
    end

    it "a bad retention_for override is rejected, not silently destructive" do
      RivetCms.revision_retention = :all
      publish("one")
      publish("two")
      publish("three")
      allow(RivetCms).to receive(:retention_for).and_return("all-ish")

      expect { described_class.new(document.reload).prune! }.to raise_error(ArgumentError, /must be :all or an Integer/)
      expect(document.reload.revisions.published.count).to eq(3)
    end

    it "fires a prune hook before destroying so subscribers can archive" do
      RivetCms.revision_retention = 0
      seen = []
      Hooks.on(:prune, key: :spec_archiver) { |revision| seen << [ revision.id, DocumentRevision.exists?(revision.id) ] }
      publish("one")
      superseded_id = document.reload.published_revision_id
      publish("two")

      expect(seen).to eq([ [ superseded_id, true ] ])
    end

    it "restores a snapshot into the draft without duplicating or colliding" do
      reference_type = create(:content_type, organization: organization)
      target = create(:document, content_type: reference_type, organization: organization)
      reference_field = create(:field, :reference, content_type: content_type, organization: organization)
      published = publish("original")
      draft.relations.create!(field: reference_field, target_document: target, position: 0)

      value = draft.content_values.find_by(field: field)
      value.update!(string_value: "edited away")

      expect { DocumentRevision.restore_owned_into(published, draft.reload) }.not_to raise_error
      expect(draft.reload.content_values.find_by(field: field).string_value).to eq("original")
      expect(draft.relations.count).to eq(0)
    end

    describe "restore guards" do
      it "refuses to restore a revision into itself" do
        published = publish("one")
        expect { DocumentRevision.restore_owned_into(published, published) }
          .to raise_error(ArgumentError, /into itself/)
        expect(published.reload.content_values.count).to eq(1)
      end

      it "refuses to overwrite a published revision" do
        published = publish("one")
        expect { DocumentRevision.restore_owned_into(draft, published) }
          .to raise_error(ArgumentError, /must be a draft/)
        expect(published.reload.content_values.first.string_value).to eq("one")
      end

      it "leaves the draft intact when the copy fails inside a caller's transaction" do
        published = publish("one")
        draft.content_values.find_by(field: field).update!(string_value: "unsaved work")
        allow(DocumentRevision).to receive(:copy_owned_into).and_raise(ActiveRecord::RecordInvalid.new(ContentValue.new))

        ActiveRecord::Base.transaction do
          DocumentRevision.restore_owned_into(published, draft.reload)
        rescue ActiveRecord::RecordInvalid
          nil # a caller swallowing the failure must not cost the draft its content
        end

        expect(draft.reload.content_values.find_by(field: field)&.string_value).to eq("unsaved work")
      end

      it "does not destroy values for soft-deleted fields it cannot restore" do
        published = publish("one")
        removed = create(:field, :string, key: "removed", content_type: content_type, organization: organization)
        draft.content_values.create!(field: removed, string_value: "keep me")
        removed.discard

        DocumentRevision.restore_owned_into(published, draft.reload)

        expect(ContentValue.where(owner: draft, field_id: removed.id).first&.string_value).to eq("keep me")
      end
    end

    it "applies a lowered retention to history when invoked directly" do
      RivetCms.revision_retention = :all
      publish("one")
      publish("two")
      publish("three")
      expect(document.reload.revisions.published.count).to eq(3)

      RivetCms.revision_retention = 0
      described_class.new(document.reload).prune!

      expect(document.reload.revisions.published.count).to eq(1)
    end
  end
end
