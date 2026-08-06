require 'rails_helper'

module RivetCms
  RSpec.describe "Content Manager", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    def publish_document(content_type, slug:, title: nil)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft, author_name: "Nathan")
      document.update!(draft_revision: draft)
      if title
        field = content_type.fields.kept.find_by(field_type: "string") ||
                create(:field, :string, key: "title", content_type: content_type, organization: organization)
        draft.content_values.create!(field: field, string_value: title)
      end
      document
    end

    it "renders the content manager home" do
      create(:content_type, organization: organization)
      get rivet_cms.content_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ContentManager/Index")
    end

    it "lists entries across types with titles and pagination" do
      posts = create(:content_type, organization: organization, name: "Post")
      pages = create(:content_type, organization: organization, name: "Page")
      publish_document(posts, slug: "first-post", title: "My First Post")
      publish_document(pages, slug: "about-us")

      get rivet_cms.content_path

      expect(response.body).to include("first-post")
      expect(response.body).to include("about-us")
      expect(response.body).to include("My First Post")
      expect(response.body).to include("pagination")
    end

    it "filters by content type slug and search query" do
      posts = create(:content_type, organization: organization, name: "Post", slug: "posts")
      pages = create(:content_type, organization: organization, name: "Page", slug: "pages")
      publish_document(posts, slug: "hello-world")
      publish_document(pages, slug: "about-us")

      get rivet_cms.content_path, params: { type: "posts" }
      expect(response.body).to include("hello-world")
      expect(response.body).not_to include("about-us")

      get rivet_cms.content_path, params: { q: "about" }
      expect(response.body).to include("about-us")
      expect(response.body).not_to include("hello-world")
    end

    it "combines the type filter with a search query" do
      posts = create(:content_type, organization: organization, name: "Post", slug: "posts")
      publish_document(posts, slug: "hello-world")
      publish_document(posts, slug: "goodbye-world")

      get rivet_cms.content_path, params: { type: "posts", q: "hello" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("hello-world")
      expect(response.body).not_to include("goodbye-world")
    end
  end
end
