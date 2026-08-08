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

    it "trashing an entry from the Content page returns there with filters intact" do
      document = create(:document, slug: "leaving", content_type: articles, organization: organization)
      document.update!(draft_revision: create(:document_revision, document: document, state: :draft))
      here = rivet_cms.content_path(type: "articles", q: "leav")

      delete rivet_cms.content_type_document_path(articles, document), headers: { "HTTP_REFERER" => here }

      expect(response).to redirect_to(here)
    end

    it "trashing an entry from its own editor falls back to the entry list" do
      document = create(:document, slug: "self-delete", content_type: articles, organization: organization)
      document.update!(draft_revision: create(:document_revision, document: document, state: :draft))
      dead = rivet_cms.edit_content_type_document_path(articles, document)

      delete rivet_cms.content_type_document_path(articles, document), headers: { "HTTP_REFERER" => dead }

      expect(response).to redirect_to(rivet_cms.content_type_documents_path(articles))
    end

    it "removing a type from its own page falls back to the types index" do
      dead = rivet_cms.content_type_path(articles)

      delete rivet_cms.content_type_path(articles), headers: { "HTTP_REFERER" => dead }

      expect(response).to redirect_to(rivet_cms.content_types_path)
    end

    it "counts the trash's contents in the sidebar badge, hiding zero" do
      get rivet_cms.root_path
      nav = JSON.parse(CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1]))["props"]["nav"]
      trash_item = nav.flat_map { |g| g["items"] }.find { |i| i["key"] == "trash" }
      expect(trash_item).not_to have_key("badge")

      trashed_entry(articles, "counted")
      notes.discard!

      get rivet_cms.root_path
      nav = JSON.parse(CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1]))["props"]["nav"]
      trash_item = nav.flat_map { |g| g["items"] }.find { |i| i["key"] == "trash" }
      expect(trash_item["badge"]).to eq(2)
    end

    it "the badge counts removed types only with schema read, like the page" do
      trashed_entry(articles, "counted")
      notes.discard!
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :schema) }

      get rivet_cms.root_path

      nav = JSON.parse(CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1]))["props"]["nav"]
      trash_item = nav.flat_map { |g| g["items"] }.find { |i| i["key"] == "trash" }
      expect(trash_item["badge"]).to eq(1)
    end

    it "a raising badge keeps the sidebar alive without a count" do
      Navigation.register :flaky, label: "Flaky", section: "Pro", path: "/flaky", badge: -> { raise "boom" }

      get rivet_cms.root_path

      expect(response).to have_http_status(:ok)
      nav = JSON.parse(CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1]))["props"]["nav"]
      flaky = nav.flat_map { |g| g["items"] }.find { |i| i["key"] == "flaky" }
      expect(flaky).to be_present
      expect(flaky).not_to have_key("badge")
    end

    it "purging from the global trash returns there with filters intact" do
      entry = trashed_entry(articles, "goner")
      here = rivet_cms.trash_path(q: "gon", type: "articles", page: 1)

      delete rivet_cms.purge_content_type_document_path(articles, entry), headers: { "HTTP_REFERER" => here }

      expect(response).to redirect_to(here)
    end

    it "purging a removed type from the global trash returns there too" do
      articles.discard!
      here = rivet_cms.trash_path

      delete rivet_cms.purge_content_type_path(articles), params: { confirm: articles.name }, headers: { "HTTP_REFERER" => here }

      expect(response).to redirect_to(here)
      expect(ContentType.with_discarded.find_by(id: articles.id)).to be_nil
    end

    it "a failed typed-name check also returns to the page it came from" do
      articles.discard!
      here = rivet_cms.trash_path

      delete rivet_cms.purge_content_type_path(articles), params: { confirm: "wrong" }, headers: { "HTTP_REFERER" => here }

      expect(response).to redirect_to(here)
      expect(ContentType.with_discarded.find_by(id: articles.id)).to be_present
    end

    it "purging without a referer falls back to the scoped trash" do
      entry = trashed_entry(articles, "goner")

      delete rivet_cms.purge_content_type_document_path(articles, entry)

      expect(response).to redirect_to(rivet_cms.trash_content_type_documents_path(articles))
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
