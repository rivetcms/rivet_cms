require 'rails_helper'

module RivetCms
  RSpec.describe "Entry trash", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }
    let(:field) { create(:field, :string, key: "title", content_type: content_type, organization: organization) }

    def published_entry(slug: "keeper", title: "Precious")
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft.content_values.create!(field: field, string_value: title)
      draft.publish!
      document
    end

    around do |example|
      original = RivetCms.can
      example.run
    ensure
      RivetCms.can = original
    end

    it "trashing keeps every revision and value" do
      entry = published_entry
      revision_ids = entry.revisions.pluck(:id)
      value_count = ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision").count

      delete rivet_cms.content_type_document_path(content_type, entry)

      expect(Document.find_by(id: entry.id)).to be_nil
      expect(Document.with_discarded.find_by(id: entry.id)).to be_present
      expect(DocumentRevision.where(id: revision_ids).count).to eq(revision_ids.size)
      expect(ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision").count).to eq(value_count)
    end

    it "stops serving a trashed entry over the delivery API" do
      RivetCms.public_api = true
      entry = published_entry
      get rivet_cms.content_show_path("articles", "keeper")
      expect(response).to have_http_status(:ok)

      delete rivet_cms.content_type_document_path(content_type, entry)

      get rivet_cms.content_show_path("articles", "keeper")
      expect(response).to have_http_status(:not_found)
      get rivet_cms.content_index_path("articles")
      expect(response.body).not_to include("keeper")
    end

    it "hides a trashed entry from the Ruby helpers" do
      RivetCms.public_api = true
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      expect(RivetCms.entry("articles", "keeper", organization: organization)).to be_nil
      expect(RivetCms.entries("articles", organization: organization).map(&:slug)).not_to include("keeper")
    end

    it "hides a trashed entry from admin lists and its editor" do
      entry = published_entry

      delete rivet_cms.content_type_document_path(content_type, entry)

      get rivet_cms.content_type_documents_path(content_type)
      expect(response.body).not_to include("Precious")
      get rivet_cms.content_path
      expect(response.body).not_to include("Precious")
      get rivet_cms.edit_content_type_document_path(content_type, entry)
      expect(response).to have_http_status(:not_found)
    end

    it "omits references pointing at a trashed entry" do
      RivetCms.public_api = true
      target = published_entry(slug: "jane", title: "Jane")
      reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      draft.publish!

      delete rivet_cms.content_type_document_path(content_type, target)

      get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("jane")
    end

    it "lists trashed entries and restores them with their content" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      get rivet_cms.trash_content_type_documents_path(content_type)
      expect(response.body).to include("Documents/Trash")
      expect(response.body).to include("keeper")

      patch rivet_cms.restore_content_type_document_path(content_type, entry)

      expect(Document.find_by(id: entry.id)).to be_present
      get rivet_cms.content_type_documents_path(content_type)
      expect(response.body).to include("Precious")
    end

    it "restoring puts the entry back on the delivery API" do
      RivetCms.public_api = true
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      patch rivet_cms.restore_content_type_document_path(content_type, entry)

      get rivet_cms.content_show_path("articles", "keeper")
      expect(response).to have_http_status(:ok)
    end

    it "keeps a trashed entry's slug reserved" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      duplicate = content_type.documents.new(slug: "keeper", organization: organization)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it "lets you keep editing an entry that references a trashed one" do
      target = published_entry(slug: "jane")
      reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      delete rivet_cms.content_type_document_path(content_type, target)

      # The editor round trips the trashed id, so saving must not fail
      patch rivet_cms.content_type_document_path(content_type, article),
            params: { values: { "author" => [ target.id ], "title" => "Still editable" } }

      expect(response).to have_http_status(:found)
      expect(flash[:notice]).to include("1 reference was removed")
      expect(draft.reload.content_values.find_by(field: field)&.string_value).to eq("Still editable")

      post rivet_cms.publish_content_type_document_path(content_type, article)
      expect(response).to have_http_status(:found)
      expect(article.reload.published_revision).to be_present
    end

    it "publishing with on-screen values also reports dropped references" do
      target = published_entry(slug: "jane")
      reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      delete rivet_cms.content_type_document_path(content_type, target)

      post rivet_cms.publish_content_type_document_path(content_type, article),
           params: { values: { "author" => [ target.id ] } }

      expect(flash[:notice]).to include("Published. 1 reference was removed")
    end

    it "restore requires content delete, the same gate as trashing" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)
      RivetCms.can = ->(check) { !(check.action == :delete && check.resource == :content) }

      patch rivet_cms.restore_content_type_document_path(content_type, entry)

      expect(Document.find_by(id: entry.id)).to be_nil
    end

    it "restore does not need content write" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)
      RivetCms.can = ->(check) { !(check.action == :write && check.resource == :content) }

      patch rivet_cms.restore_content_type_document_path(content_type, entry)

      expect(Document.find_by(id: entry.id)).to be_present
    end

    it "a required reference to a trashed entry fails validation instead of publishing empty" do
      target = published_entry(slug: "jane")
      reference = create(:field, :reference, key: "author", content_type: content_type,
                                             organization: organization, required: true, min_items: 1)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      delete rivet_cms.content_type_document_path(content_type, target)

      expect { draft.reload.publish! }.to raise_error(ContentInvalidError)
      expect(article.reload.published_revision).to be_nil
    end

    it "writing or publishing a trashed entry says so instead of NoMethodError" do
      entry = published_entry
      revision = entry.draft_revision
      delete rivet_cms.content_type_document_path(content_type, entry)

      expect { revision.reload.publish! }.to raise_error(TrashedEntryError, /restore it/)
      expect { DraftWriter.new(revision).write({}) }.to raise_error(TrashedEntryError, /restore it/)
      expect { ContentValidator.new(revision).validate }.to raise_error(TrashedEntryError, /restore it/)
    end

    it "publishes an entry whose reference was trashed without saving first" do
      target = published_entry(slug: "jane")
      reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      delete rivet_cms.content_type_document_path(content_type, target)

      # No save first, so the dangling relation is still on the draft
      expect { draft.reload.publish! }.not_to raise_error
      expect(article.reload.published_revision.relations).to be_empty
    end

    it "purging a content type takes its trashed entries with it" do
      kept = published_entry(slug: "kept")
      trashed = published_entry(slug: "trashed")
      delete rivet_cms.content_type_document_path(content_type, trashed)
      delete rivet_cms.content_type_path(content_type)

      delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

      expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_nil
      expect(Document.with_discarded.where(id: [ kept.id, trashed.id ])).to be_empty
    end

    it "destroying an organization takes trashed entries with it" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)
      org_id = organization.id

      expect { organization.reload.destroy }.not_to raise_error
      expect(Organization.exists?(org_id)).to be false
      expect(Document.with_discarded.where(id: entry.id)).to be_empty
    end

    it "a trashed entry still blocks destroying its content type" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      expect(ContentType.find(content_type.id).destroy).to be false
      expect(ContentType.exists?(content_type.id)).to be true
    end

    it "the trash is scoped to its own content type" do
      other_type = create(:content_type, slug: "notes", organization: organization)
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      get rivet_cms.trash_content_type_documents_path(other_type)
      # assert on props, not the body: the flash still names the entry
      expect(CGI.unescapeHTML(response.body)).to include('"documents":[]')

      patch rivet_cms.restore_content_type_document_path(other_type, entry)
      expect(response).to have_http_status(:not_found)
    end

    it "the trash lists only trashed entries, and the count matches" do
      published_entry(slug: "live")
      trashed = published_entry(slug: "gone")
      delete rivet_cms.content_type_document_path(content_type, trashed)

      get rivet_cms.trash_content_type_documents_path(content_type)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include('"slug":"gone"')
      expect(body).not_to include('"slug":"live"')

      get rivet_cms.content_type_documents_path(content_type)
      expect(CGI.unescapeHTML(response.body)).to include('"trashed_count":1')
    end

    it "points at the trash when recreating a slug held by a trashed entry" do
      entry = published_entry
      delete rivet_cms.content_type_document_path(content_type, entry)

      post rivet_cms.content_type_documents_path(content_type), params: { slug: "keeper" }

      follow_redirect!
      body = CGI.unescapeHTML(response.body)
      expect(body).to include("belongs to an entry in the trash")
      expect(body).not_to include("has already been taken")
      expect(Document.with_discarded.where(slug: "keeper").count).to eq(1)
    end

    it "explains a trashed single instead of a singleton key error" do
      single_type = create(:content_type, :single, slug: "homepage", organization: organization)
      entry = create(:document, slug: "homepage", content_type: single_type, organization: organization)
      draft = create(:document_revision, document: entry, state: :draft)
      entry.update!(draft_revision: draft)
      delete rivet_cms.content_type_document_path(single_type, entry)

      post rivet_cms.content_type_documents_path(single_type), params: { slug: "homepage-2" }

      follow_redirect!
      body = CGI.unescapeHTML(response.body)
      expect(body).to include("restore it instead of creating a new one")
      expect(body).not_to include("has already been taken")
    end

    describe "permanent delete" do
      it "destroys the entry and its revisions" do
        entry = published_entry
        revision_ids = entry.revisions.pluck(:id)
        delete rivet_cms.content_type_document_path(content_type, entry)

        delete rivet_cms.purge_content_type_document_path(content_type, entry)

        expect(Document.with_discarded.find_by(id: entry.id)).to be_nil
        expect(DocumentRevision.where(id: revision_ids)).to be_empty
        expect(ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision")).to be_empty
      end

      it "clears incoming references so the purge cannot fail on a foreign key" do
        target = published_entry(slug: "jane")
        reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
        referrer = create(:document, slug: "hello", content_type: content_type, organization: organization)
        draft = create(:document_revision, document: referrer, state: :draft)
        referrer.update!(draft_revision: draft)
        draft.relations.create!(field: reference, target_document: target, position: 0)
        delete rivet_cms.content_type_document_path(content_type, target)

        expect {
          delete rivet_cms.purge_content_type_document_path(content_type, target)
        }.not_to raise_error

        expect(Document.with_discarded.find_by(id: target.id)).to be_nil
        expect(Document.exists?(referrer.id)).to be true
      end

      it "cannot purge an entry that is not in the trash" do
        entry = published_entry

        delete rivet_cms.purge_content_type_document_path(content_type, entry)

        expect(response).to have_http_status(:not_found)
        expect(Document.exists?(entry.id)).to be true
      end

      it "requires content delete" do
        entry = published_entry
        delete rivet_cms.content_type_document_path(content_type, entry)
        RivetCms.can = ->(check) { !(check.action == :delete && check.resource == :content) }

        delete rivet_cms.purge_content_type_document_path(content_type, entry)

        expect(Document.with_discarded.find_by(id: entry.id)).to be_present
      end

      it "reports a failed purge instead of crashing, keeping the entry" do
        entry = published_entry
        delete rivet_cms.content_type_document_path(content_type, entry)
        allow_any_instance_of(Document).to receive(:destroy!).and_raise(ActiveRecord::InvalidForeignKey, "boom")

        delete rivet_cms.purge_content_type_document_path(content_type, entry)

        expect(flash[:alert]).to include("could not be deleted")
        expect(Document.with_discarded.find_by(id: entry.id)).to be_present
      end
    end
  end
end
