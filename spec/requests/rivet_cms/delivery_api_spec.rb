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
  end
end
