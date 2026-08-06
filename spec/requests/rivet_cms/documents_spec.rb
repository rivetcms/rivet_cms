require 'rails_helper'

module RivetCms
  RSpec.describe "Documents (admin)", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, organization: organization) }

    it "renders the entries list page" do
      get rivet_cms.content_type_documents_path(content_type)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Documents/Index")
    end

    it "filters the entries list by slug with q" do
      create(:document, slug: "hello-world", content_type: content_type, organization: organization)
      create(:document, slug: "other-post", content_type: content_type, organization: organization)

      get rivet_cms.content_type_documents_path(content_type), params: { q: "HELLO" }

      expect(response.body).to include("hello-world")
      expect(response.body).not_to include("other-post")
    end

    it "renders the new entry editor with the content-type fields" do
      create(:field, :string, label: "Headline", content_type: content_type, organization: organization)
      get rivet_cms.new_content_type_document_path(content_type)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Documents/Edit")
      expect(response.body).to include("Headline")
    end

    it "creates a document with a draft and scalar values" do
      field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
      expect {
        post rivet_cms.content_type_documents_path(content_type), params: { slug: "about", values: { title: "Hi" } }
      }.to change(Document, :count).by(1)

      document = Document.last
      expect(document.draft_revision.content_values.find_by(field: field).string_value).to eq("Hi")
    end

    it "writes reference relations via the draft writer" do
      target = create(:document, content_type: content_type, organization: organization)
      create(:field, field_type: :reference, key: "related", content_type: content_type, organization: organization)
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "src" }
      document = Document.last

      patch rivet_cms.content_type_document_path(content_type, document), params: { values: { related: [ target.id ] } }
      expect(document.draft_revision.relations.map(&:target_document_id)).to eq([ target.id ])
    end

    it "writes component instances with nested values" do
      component = create(:component, organization: organization)
      heading = create(:field, :for_component, key: "heading", component: component, organization: organization)
      create(:field, field_type: :component, key: "blocks", content_type: content_type,
                     organization: organization, config: { "component_id" => component.id })

      post rivet_cms.content_type_documents_path(content_type), params: { slug: "composed" }
      document = Document.last

      patch rivet_cms.content_type_document_path(content_type, document), params: {
        values: { blocks: [ { values: { heading: "First" } }, { values: { heading: "Second" } } ] }
      }, as: :json

      instances = document.draft_revision.component_instances.ordered
      expect(instances.size).to eq(2)
      expect(instances.first.content_values.find_by(field: heading).string_value).to eq("First")
      expect(instances.last.content_values.find_by(field: heading).string_value).to eq("Second")

      get rivet_cms.edit_content_type_document_path(content_type, document)
      expect(response.body).to include("First")
    end

    it "publishes a valid draft" do
      create(:field, :string, key: "title", content_type: content_type, organization: organization)
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "about", values: { title: "Hi" } }
      document = Document.last

      post rivet_cms.publish_content_type_document_path(content_type, document)
      expect(document.reload.published_revision).to be_present
    end

    it "does not publish an invalid draft" do
      create(:field, :string, key: "title", required: true, content_type: content_type, organization: organization)
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "about" }
      document = Document.last

      post rivet_cms.publish_content_type_document_path(content_type, document)
      expect(document.reload.published_revision).to be_nil
    end

    it "validates and saves on-screen values submitted with publish" do
      create(:field, :string, key: "email", content_type: content_type, organization: organization,
                              config: { "pattern" => "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" })
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "about" }
      document = Document.last

      # Unsaved edit arrives with publish: it must be validated AND persisted.
      post rivet_cms.publish_content_type_document_path(content_type, document), params: { values: { email: "bad" } }
      expect(document.reload.published_revision).to be_nil
      expect(document.draft_revision.content_values.first.value).to eq("bad")

      post rivet_cms.publish_content_type_document_path(content_type, document), params: { values: { email: "a@b.co" } }
      expect(document.reload.published_revision).to be_present
    end

    it "does not publish a select value outside the configured choices" do
      create(:field, :enumeration, key: "status", content_type: content_type, organization: organization)
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "about", values: { status: "bogus" } }
      document = Document.last

      post rivet_cms.publish_content_type_document_path(content_type, document)
      expect(document.reload.published_revision).to be_nil
    end

    it "deletes an entry" do
      post rivet_cms.content_type_documents_path(content_type), params: { slug: "gone" }
      document = Document.last

      expect {
        delete rivet_cms.content_type_document_path(content_type, document)
      }.to change(Document, :count).by(-1)
    end
  end
end
