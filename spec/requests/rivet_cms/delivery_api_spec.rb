require 'rails_helper'

module RivetCms
  RSpec.describe "Delivery API access", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }
    let(:title_field) { create(:field, :string, key: "title", content_type: content_type, organization: organization) }
    let(:date_field) { create(:field, field_type: :datetime, key: "starts_at", content_type: content_type, organization: organization) }

    def bearer(token)
      { "Authorization" => "Bearer #{token}" }
    end

    def publish(slug:, title: "T", starts_at: nil)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft.content_values.create!(field: title_field, string_value: title)
      draft.content_values.create!(field: date_field, datetime_value: starts_at) if starts_at
      draft.publish!
      document
    end

    describe "access control" do
      it "401s without a token when public_api is off" do
        get rivet_cms.content_index_path("articles")
        expect(response).to have_http_status(:unauthorized)
      end

      it "200s without a token when public_api is on" do
        RivetCms.public_api = true
        content_type
        get rivet_cms.content_index_path("articles")
        expect(response).to have_http_status(:ok)
      end

      it "200s with a valid token" do
        token = ApiToken.generate!(name: "CI", organization: organization)
        content_type
        get rivet_cms.content_index_path("articles"), headers: bearer(token.plaintext)
        expect(response).to have_http_status(:ok)
      end

      it "401s for an invalid token" do
        content_type
        get rivet_cms.content_index_path("articles"), headers: bearer("bogus")
        expect(response).to have_http_status(:unauthorized)
      end

      it "isolates content by the token's organization" do
        other = create(:organization)
        create(:content_type, slug: "articles", organization: other)
        token = ApiToken.generate!(name: "other", organization: other)

        # Our org also has an "articles" type, but the token belongs to `other`.
        content_type
        get rivet_cms.content_index_path("articles"), headers: bearer(token.plaintext)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["meta"]["total"]).to eq(0)
      end
    end

    describe "preview scope" do
      it "serves a draft-only document to a preview token" do
        title_field
        document = create(:document, slug: "wip", content_type: content_type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.content_values.create!(field: title_field, string_value: "Work in progress")

        token = ApiToken.generate!(name: "preview", scope: :preview, organization: organization)
        get rivet_cms.content_show_path("articles", "wip") + "?preview=true", headers: bearer(token.plaintext)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).dig("data", "title")).to eq("Work in progress")
      end

      it "403s a preview request from a published-scope token" do
        publish(slug: "live")
        token = ApiToken.generate!(name: "pub", organization: organization)
        get rivet_cms.content_show_path("articles", "live") + "?preview=true", headers: bearer(token.plaintext)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "list ergonomics" do
      before { RivetCms.public_api = true }

      it "paginates with a meta envelope and caps per_page" do
        3.times { |i| publish(slug: "a#{i}") }
        get rivet_cms.content_index_path("articles"), params: { per_page: 2 }

        body = JSON.parse(response.body)
        expect(body["data"].size).to eq(2)
        expect(body["meta"]).to include("total" => 3, "total_pages" => 2, "per_page" => 2)
      end

      it "sorts by a datetime field key" do
        publish(slug: "late", starts_at: Time.zone.parse("2026-12-01 10:00"))
        publish(slug: "early", starts_at: Time.zone.parse("2026-08-01 10:00"))

        get rivet_cms.content_index_path("articles"), params: { sort: "starts_at" }
        slugs = JSON.parse(response.body)["data"].map { |d| d["slug"] }
        expect(slugs).to eq(%w[early late])
      end

      it "filters a datetime field by range" do
        publish(slug: "aug", starts_at: Time.zone.parse("2026-08-15 10:00"))
        publish(slug: "dec", starts_at: Time.zone.parse("2026-12-15 10:00"))

        get rivet_cms.content_index_path("articles"), params: { starts_at: { gte: "2026-10-01" } }
        slugs = JSON.parse(response.body)["data"].map { |d| d["slug"] }
        expect(slugs).to contain_exactly("dec")
      end

      it "400s on an unknown sort field" do
        content_type
        get rivet_cms.content_index_path("articles"), params: { sort: "bogus" }
        expect(response).to have_http_status(:bad_request)
      end

      it "returns a JSON 404 for an unknown content type" do
        get rivet_cms.content_index_path("no-such-type")
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include("error")
      end

      it "accepts a lowercase bearer scheme" do
        RivetCms.public_api = false
        token = ApiToken.generate!(name: "lc", organization: organization)
        content_type
        get rivet_cms.content_index_path("articles"), headers: { "Authorization" => "bearer #{token.plaintext}" }
        expect(response).to have_http_status(:ok)
      end
    end

    describe "populate and fields" do
      before { RivetCms.public_api = true }

      let(:authors) { create(:content_type, slug: "authors", organization: organization) }
      let(:author_name_field) { create(:field, :string, key: "name", content_type: authors, organization: organization) }
      let(:author_field) do
        create(:field, field_type: :reference, key: "author", max_items: 1, content_type: content_type, organization: organization)
      end
      let(:categories_field) do
        create(:field, field_type: :reference, key: "categories", content_type: content_type, organization: organization)
      end

      def publish_author(slug:, name: "Jane")
        document = create(:document, slug: slug, content_type: authors, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.content_values.create!(field: author_name_field, string_value: name)
        draft.publish!
        document
      end

      def draft_only_author(slug:)
        document = create(:document, slug: slug, content_type: authors, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        document
      end

      def publish_with_relations(slug:, field_targets:)
        document = create(:document, slug: slug, content_type: content_type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: draft)
        draft.content_values.create!(field: title_field, string_value: "T")
        field_targets.each do |field, targets|
          Array(targets).each_with_index do |target, index|
            draft.relations.create!(field: field, target_document: target, position: index)
          end
        end
        draft.publish!
        document
      end

      it "expands a populated max_items 1 reference into a single full document" do
        jane = publish_author(slug: "jane")
        publish_with_relations(slug: "hello", field_targets: { author_field => jane })

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }
        author = JSON.parse(response.body).dig("data", "author")

        expect(author).to include("slug" => "jane", "content_type" => "authors", "state" => "published")
        expect(author.dig("data", "name")).to eq("Jane")
      end

      it "keeps references shallow without populate" do
        jane = publish_author(slug: "jane")
        publish_with_relations(slug: "hello", field_targets: { categories_field => [ jane ] })

        get rivet_cms.content_show_path("articles", "hello")
        refs = JSON.parse(response.body).dig("data", "categories")

        expect(refs).to eq([ { "id" => jane.prefix_id, "slug" => "jane" } ])
      end

      it "keeps a populated target's own references shallow (one level deep)" do
        author_related_field = create(:field, field_type: :reference, key: "related", content_type: authors,
                                              organization: organization)
        bob = publish_author(slug: "bob", name: "Bob")
        jane_doc = create(:document, slug: "jane", content_type: authors, organization: organization)
        jane_draft = create(:document_revision, document: jane_doc, state: :draft)
        jane_doc.update!(draft_revision: jane_draft)
        jane_draft.content_values.create!(field: author_name_field, string_value: "Jane")
        jane_draft.relations.create!(field: author_related_field, target_document: bob, position: 0)
        jane_draft.publish!
        publish_with_relations(slug: "hello", field_targets: { author_field => jane_doc })

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }
        related = JSON.parse(response.body).dig("data", "author", "data", "related")

        expect(related).to eq([ { "id" => bob.prefix_id, "slug" => "bob" } ])
      end

      it "rejects array and hash populate or fields params with a 400" do
        title_field
        publish(slug: "hello")

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: [ "author" ] }
        expect(response).to have_http_status(:bad_request)

        get rivet_cms.content_show_path("articles", "hello"), params: { fields: { a: "b" } }
        expect(response).to have_http_status(:bad_request)
      end

      it "treats a separator-only fields param as absent" do
        title_field
        publish(slug: "hello")

        get rivet_cms.content_show_path("articles", "hello"), params: { fields: ",," }
        expect(JSON.parse(response.body)["data"]).to include("title" => "T")
      end

      it "populates all reference fields with populate=*" do
        jane = publish_author(slug: "jane")
        bob = publish_author(slug: "bob", name: "Bob")
        publish_with_relations(slug: "hello", field_targets: { author_field => jane, categories_field => [ bob ] })

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "*" }
        data = JSON.parse(response.body)["data"]

        expect(data.dig("author", "data", "name")).to eq("Jane")
        expect(data["categories"].sole.dig("data", "name")).to eq("Bob")
      end

      it "400s for an unknown or non-reference populate key" do
        title_field
        publish(slug: "hello")

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "bogus" }
        expect(response).to have_http_status(:bad_request)

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "title" }
        expect(response).to have_http_status(:bad_request)
      end

      it "selects sparse fields and 400s on unknown keys" do
        date_field
        publish(slug: "hello", starts_at: Time.zone.parse("2026-08-01 10:00"))

        get rivet_cms.content_show_path("articles", "hello"), params: { fields: "title" }
        expect(JSON.parse(response.body)["data"].keys).to eq([ "title" ])

        get rivet_cms.content_show_path("articles", "hello"), params: { fields: "bogus" }
        expect(response).to have_http_status(:bad_request)
      end

      it "omits relations to draft-only documents in published scope" do
        hidden = draft_only_author(slug: "hidden")
        publish_with_relations(slug: "hello", field_targets: { author_field => hidden, categories_field => [ hidden ] })

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }
        data = JSON.parse(response.body)["data"]

        expect(data["author"]).to be_nil
        expect(data["categories"]).to eq([])
      end

      it "serves draft target values to a preview request" do
        jane = publish_author(slug: "jane")
        new_draft = create(:document_revision, document: jane, state: :draft)
        jane.update!(draft_revision: new_draft)
        new_draft.content_values.create!(field: author_name_field, string_value: "Jane v2")
        publish_with_relations(slug: "hello", field_targets: { author_field => jane })

        token = ApiToken.generate!(name: "preview", scope: :preview, organization: organization)
        get rivet_cms.content_show_path("articles", "hello"), params: { preview: "true", populate: "author" },
            headers: bearer(token.plaintext)

        expect(JSON.parse(response.body).dig("data", "author", "data", "name")).to eq("Jane v2")
      end

      it "populates on the list endpoint" do
        jane = publish_author(slug: "jane")
        publish_with_relations(slug: "a1", field_targets: { author_field => jane })
        publish_with_relations(slug: "a2", field_targets: { author_field => jane })

        get rivet_cms.content_index_path("articles"), params: { populate: "author" }
        data = JSON.parse(response.body)["data"]

        expect(data.map { |doc| doc.dig("data", "author", "data", "name") }.uniq).to eq([ "Jane" ])
      end

      def count_sql
        count = 0
        counter = ->(_name, _start, _finish, _id, payload) {
          count += 1 unless payload[:name] == "SCHEMA" || payload[:cached]
        }
        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
        count
      end

      it "runs a constant number of queries regardless of page size" do
        jane = publish_author(slug: "jane")
        list = -> { get rivet_cms.content_index_path("articles"), params: { populate: "*", per_page: 50 } }

        (1..2).each { |i| publish_with_relations(slug: "doc#{i}", field_targets: { author_field => jane, categories_field => [ jane ] }) }
        small = count_sql(&list)

        (3..8).each { |i| publish_with_relations(slug: "doc#{i}", field_targets: { author_field => jane, categories_field => [ jane ] }) }
        large = count_sql(&list)

        expect(response).to have_http_status(:ok)
        expect(large).to eq(small)
      end
    end
  end
end
