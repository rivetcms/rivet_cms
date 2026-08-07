require 'rails_helper'

module RivetCms
  RSpec.describe "Audit stream", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }
    let(:events) { [] }

    before do
      organization
      captured = events
      RivetCms.on(:audit, key: :spec_recorder) { |event| captured << event }
    end

    def entry(slug = "keeper")
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      document
    end

    def actions
      events.map(&:action)
    end

    it "covers the entry lifecycle end to end" do
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "story" }
      document = Document.find_by!(slug: "story")
      patch rivet_cms.content_type_document_path(content_type, document), params: { values: {} }
      post rivet_cms.publish_content_type_document_path(content_type, document)
      delete rivet_cms.content_type_document_path(content_type, document)
      patch rivet_cms.restore_content_type_document_path(content_type, document)
      delete rivet_cms.content_type_document_path(content_type, document)
      delete rivet_cms.purge_content_type_document_path(content_type, document)

      expect(actions).to eq(%w[
        entry.created entry.updated entry.published entry.trashed
        entry.restored entry.trashed entry.purged
      ])
    end

    it "carries subject identity, organization, and timestamp" do
      document = entry
      delete rivet_cms.content_type_document_path(content_type, document)

      event = events.last
      expect(event.action).to eq("entry.trashed")
      expect(event.subject_type).to eq("document")
      expect(event.subject_id).to eq(document.prefix_id)
      expect(event.subject_label).to eq("keeper")
      expect(event.organization_id).to eq(organization.id)
      expect(event.at).to be_within(5).of(Time.current)
    end

    it "does not fire when the mutation fails" do
      entry
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "keeper" }

      expect(actions).not_to include("entry.created")
    end

    it "does not fire when a purge rolls back" do
      document = entry
      delete rivet_cms.content_type_document_path(content_type, document)
      events.clear
      allow_any_instance_of(Document).to receive(:destroy!).and_raise(ActiveRecord::InvalidForeignKey, "boom")

      delete rivet_cms.purge_content_type_document_path(content_type, document)

      expect(actions).not_to include("entry.purged")
    end

    it "covers schema changes" do
      post rivet_cms.content_types_path, params: { content_type: { name: "Notes", slug: "notes" } }
      notes = ContentType.find_by!(slug: "notes")
      post rivet_cms.content_type_fields_path(notes), params: { field: { label: "Title", key: "title", field_type: "string" } }
      field = notes.fields.find_by!(key: "title")
      delete rivet_cms.content_type_field_path(notes, field)
      delete rivet_cms.content_type_path(notes)

      expect(actions).to eq(%w[content_type.created field.created field.removed content_type.removed])
    end

    it "covers media and tokens" do
      file = Tempfile.new([ "pic", ".png" ])
      file.binmode
      file.write("\x89PNG\r\n\x1a\n".b + "fake-image")
      file.rewind
      post rivet_cms.media_assets_path, params: { file: Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "pic.png") }
      post rivet_cms.api_tokens_path, params: { name: "deploy", scope: "published" }
      token = ApiToken.find_by!(name: "deploy")
      delete rivet_cms.api_token_path(token)

      expect(actions).to eq(%w[media.uploaded api_token.created api_token.revoked])
      expect(events.first.subject_label).to eq("pic.png")
      expect(events.second.metadata).to eq({ scope: "published" })
    end

    it "a raising subscriber does not break the admin" do
      RivetCms.on(:audit, key: :broken) { raise "boom" }
      document = entry

      delete rivet_cms.content_type_document_path(content_type, document)

      expect(response).to redirect_to(rivet_cms.content_type_documents_path(content_type))
      expect(Document.with_discarded.find_by(id: document.id)).to be_discarded
    end
  end
end
