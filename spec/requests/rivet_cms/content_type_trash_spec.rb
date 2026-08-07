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

    it "hides entry counts from a user who cannot read content" do
      entry
      delete rivet_cms.content_type_path(content_type)
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :content) }

      get rivet_cms.trash_content_types_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("documents_count")
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
