require 'rails_helper'

module RivetCms
  RSpec.describe "Content type trash", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    def entry
      @entry ||= begin
        document = create(:document, slug: "keeper", content_type: content_type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.publish!
        document
      end
    end

    around do |example|
      original = RivetCms.can
      example.run
    ensure
      RivetCms.can = original
    end

    it "lists removed types with the entries they are holding" do
      entry
      delete rivet_cms.content_type_path(content_type)

      get rivet_cms.trash_content_types_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ContentTypes/Trash")
      expect(response.body).to include("articles")
      expect(response.body).to include("documents_count")
    end

    it "restores a type and its entries from the trash" do
      entry
      delete rivet_cms.content_type_path(content_type)

      patch rivet_cms.restore_content_type_path(content_type)

      expect(response).to redirect_to(rivet_cms.content_type_path(content_type))
      expect(ContentType.find_by(id: content_type.id)).to be_present
      get rivet_cms.content_type_documents_path(content_type)
      expect(response.body).to include("keeper")
    end

    it "restoring puts the entries back on the delivery API" do
      RivetCms.public_api = true
      entry
      delete rivet_cms.content_type_path(content_type)
      get rivet_cms.content_index_path("articles")
      expect(response).to have_http_status(:not_found)

      patch rivet_cms.restore_content_type_path(content_type)

      get rivet_cms.content_index_path("articles")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("keeper")
    end

    it "does not restore a type that was never removed" do
      content_type

      patch rivet_cms.restore_content_type_path(content_type)

      expect(response).to have_http_status(:not_found)
    end

    it "surfaces the removed count on the index only when something is removed" do
      content_type
      get rivet_cms.content_types_path
      expect(CGI.unescapeHTML(response.body)).to include('"removed_count":0')

      delete rivet_cms.content_type_path(content_type)

      get rivet_cms.content_types_path
      expect(CGI.unescapeHTML(response.body)).to include('"removed_count":1')
    end

    it "counts trashed entries a removed type is holding" do
      entry
      delete rivet_cms.content_type_document_path(content_type, entry)
      delete rivet_cms.content_type_path(content_type)

      get rivet_cms.trash_content_types_path

      expect(CGI.unescapeHTML(response.body)).to include('"documents_count":1')
    end

    it "removing a type whose entries are all trashed still needs content delete" do
      entry
      delete rivet_cms.content_type_document_path(content_type, entry)
      RivetCms.can = ->(check) { !(check.action == :delete && check.resource == :content) }

      delete rivet_cms.content_type_path(content_type)

      expect(ContentType.find_by(id: content_type.id)).to be_present
    end

    it "hides entry counts from a user who cannot read content" do
      entry
      delete rivet_cms.content_type_path(content_type)
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :content) }

      get rivet_cms.trash_content_types_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("documents_count")
    end

    describe "permanent delete" do
      it "destroys the type and everything under it when the name matches" do
        entry
        revision_ids = entry.revisions.pluck(:id)
        delete rivet_cms.content_type_path(content_type)

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_nil
        expect(Document.exists?(entry.id)).to be false
        expect(DocumentRevision.where(id: revision_ids)).to be_empty
        expect(ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision")).to be_empty
      end

      it "refuses when the typed name does not match, keeping everything" do
        entry
        delete rivet_cms.content_type_path(content_type)

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: "wrong" }

        expect(flash[:alert]).to include("Type the name exactly")
        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
        expect(Document.exists?(entry.id)).to be true
      end

      it "refuses with no confirmation at all" do
        entry
        delete rivet_cms.content_type_path(content_type)

        delete rivet_cms.purge_content_type_path(content_type)

        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
      end

      it "cannot purge a type that is not in the trash" do
        entry

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(response).to have_http_status(:not_found)
        expect(ContentType.exists?(content_type.id)).to be true
      end

      it "clears incoming references so the purge cannot fail on a foreign key" do
        other_type = create(:content_type, slug: "notes", organization: organization)
        referrer = create(:document, slug: "referrer", content_type: other_type, organization: organization)
        draft = create(:document_revision, document: referrer, state: :draft)
        referrer.update!(draft_revision: draft)
        field = create(:field, :reference, key: "author", content_type: other_type, organization: organization)
        draft.relations.create!(field: field, target_document: entry, position: 0)
        delete rivet_cms.content_type_path(content_type)

        expect {
          delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }
        }.not_to raise_error

        expect(Document.exists?(entry.id)).to be false
        expect(Document.exists?(referrer.id)).to be true
        expect(Relation.where(target_document_id: entry.id)).to be_empty
      end

      it "requires schema delete, not merely schema write" do
        entry
        delete rivet_cms.content_type_path(content_type)
        RivetCms.can = ->(check) { !(check.action == :delete && check.resource == :schema) }

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
        expect(Document.exists?(entry.id)).to be true
      end

      it "does not touch relations belonging to other content types" do
        other_type = create(:content_type, slug: "notes", organization: organization)
        a = create(:document, slug: "a", content_type: other_type, organization: organization)
        b = create(:document, slug: "b", content_type: other_type, organization: organization)
        draft = create(:document_revision, document: a, state: :draft)
        a.update!(draft_revision: draft)
        field = create(:field, :reference, key: "rel", content_type: other_type, organization: organization)
        unrelated = draft.relations.create!(field: field, target_document: b, position: 0)
        entry
        delete rivet_cms.content_type_path(content_type)

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(Relation.exists?(unrelated.id)).to be true
      end

      it "rolls everything back when the destroy fails" do
        entry
        delete rivet_cms.content_type_path(content_type)
        allow_any_instance_of(ContentType).to receive(:destroy!).and_raise(ActiveRecord::InvalidForeignKey, "boom")

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(flash[:alert]).to include("could not be deleted")
        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
        expect(Document.exists?(entry.id)).to be true
      end

      it "matches the typed name case sensitively" do
        entry
        delete rivet_cms.content_type_path(content_type)

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name.upcase }

        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
      end

      it "matches a name saved with surrounding whitespace" do
        padded = create(:content_type, name: "Padded ", slug: "padded", organization: organization)
        delete rivet_cms.content_type_path(padded)

        delete rivet_cms.purge_content_type_path(padded), params: { confirm: "Padded" }

        expect(ContentType.with_discarded.find_by(id: padded.id)).to be_nil
      end

      it "requires content delete as well as schema delete" do
        entry
        delete rivet_cms.content_type_path(content_type)
        RivetCms.can = ->(check) { !(check.action == :delete && check.resource == :content) }

        delete rivet_cms.purge_content_type_path(content_type), params: { confirm: content_type.name }

        expect(ContentType.with_discarded.find_by(id: content_type.id)).to be_present
        expect(Document.exists?(entry.id)).to be true
      end
    end

    it "requires schema write to restore" do
      entry
      delete rivet_cms.content_type_path(content_type)
      RivetCms.can = ->(check) { !(check.action == :write && check.resource == :schema) }

      patch rivet_cms.restore_content_type_path(content_type)

      expect(ContentType.find_by(id: content_type.id)).to be_nil
    end

    it "requires schema read to view the trash" do
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :schema) }

      get rivet_cms.trash_content_types_path

      expect(response).not_to have_http_status(:ok)
    end
  end
end
