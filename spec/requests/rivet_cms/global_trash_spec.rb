require 'rails_helper'

module RivetCms
  RSpec.describe "Global trash", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:articles) { create(:content_type, slug: "articles", organization: organization) }
    let(:notes) { create(:content_type, slug: "notes", organization: organization) }

    def trashed_entry(content_type, slug)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      document.update!(draft_revision: create(:document_revision, document: document, state: :draft))
      document.discard!
      document
    end

    def props
      page = response.body[/data-page="([^"]*)"/, 1]
      JSON.parse(CGI.unescapeHTML(page))["props"]
    end

    before { organization }

    it "lists trashed entries across types, each naming its type" do
      trashed_entry(articles, "lost-article")
      trashed_entry(notes, "lost-note")

      get rivet_cms.trash_path

      slugs = props["documents"].map { |d| d["slug"] }
      expect(slugs).to contain_exactly("lost-article", "lost-note")
      types = props["documents"].to_h { |d| [ d["slug"], d["content_type_name"] ] }
      expect(types["lost-article"]).to eq(articles.name)
      expect(types["lost-note"]).to eq(notes.name)
    end

    it "provides working restore paths" do
      entry = trashed_entry(articles, "come-back")
      get rivet_cms.trash_path
      restore_path = props["documents"].first["paths"]["restore"]

      patch restore_path

      expect(Document.find_by(id: entry.id)).to be_present
    end

    it "lists removed types with their kept entries, but not live ones" do
      trashed_entry(articles, "held")
      articles.discard!
      notes

      get rivet_cms.trash_path

      expect(props["content_types"].map { |ct| ct["slug"] }).to eq([ "articles" ])
      expect(props["content_types"].first["documents_count"]).to eq(1)
    end

    it "does not list entries whose type was removed; the type represents them" do
      trashed_entry(articles, "held")
      articles.discard!

      get rivet_cms.trash_path

      expect(props["documents"]).to be_empty
      expect(props["content_types"].map { |ct| ct["slug"] }).to eq([ "articles" ])
    end

    it "filters by search and type together, offering only trashed types" do
      trashed_entry(articles, "hello-article")
      trashed_entry(articles, "other-article")
      trashed_entry(notes, "hello-note")
      create(:content_type, slug: "untouched", organization: organization)

      get rivet_cms.trash_path, params: { q: "hello", type: "articles" }

      expect(props["documents"].map { |d| d["slug"] }).to eq([ "hello-article" ])
      expect(props["types"].map { |t| t["slug"] }).to contain_exactly("articles", "notes")
    end

    it "paginates entries at 25 per page, newest trashings first" do
      26.times { |i| trashed_entry(articles, "entry-#{i}") }

      get rivet_cms.trash_path
      expect(props["documents"].size).to eq(25)
      expect(props["pagination"]).to eq({ "page" => 1, "total_pages" => 2 })
      expect(props["documents"].first["slug"]).to eq("entry-25")

      get rivet_cms.trash_path, params: { page: 2 }
      expect(props["documents"].map { |d| d["slug"] }).to eq([ "entry-0" ])
    end

    it "requires content read" do
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :content) }

      get rivet_cms.trash_path

      expect(response).not_to have_http_status(:ok)
    end

    it "hides the removed-types section without schema read" do
      articles.discard!
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :schema) }

      get rivet_cms.trash_path

      expect(response).to have_http_status(:ok)
      expect(props["content_types"]).to be_empty
    end

    it "hides a denied type's trashed entries" do
      trashed_entry(articles, "visible-entry")
      trashed_entry(notes, "hidden-entry")
      RivetCms.can = ->(check) { check.record != notes }

      get rivet_cms.trash_path

      expect(props["documents"].map { |d| d["slug"] }).to eq([ "visible-entry" ])
    end
  end
end
