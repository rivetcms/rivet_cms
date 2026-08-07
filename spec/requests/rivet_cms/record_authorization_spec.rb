require 'rails_helper'

# The record phase of the can? contract: after the recordless fail-fast
# check, every member action re-checks with the loaded record so a policy
# can grant per-type or per-record access.
module RivetCms
  RSpec.describe "Record-level authorization", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    let(:seen) { [] }

    def observe!
      checks = seen
      RivetCms.can = ->(check) { checks << [ check.action, check.resource, check.record ]; true }
    end

    def entry(slug = "keeper")
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      document
    end

    before { organization }

    describe "which record each action passes" do
      it "entry actions pass the document, lists and creation pass the type" do
        document = entry
        observe!

        get rivet_cms.content_type_documents_path(content_type)
        expect(seen).to include([ :read, :content, content_type ])

        get rivet_cms.edit_content_type_document_path(content_type, document)
        expect(seen).to include([ :read, :content, document ])

        patch rivet_cms.content_type_document_path(content_type, document), params: { values: {} }
        expect(seen).to include([ :write, :content, document ])

        post rivet_cms.publish_content_type_document_path(content_type, document)
        expect(seen).to include([ :publish, :content, document ])

        delete rivet_cms.content_type_document_path(content_type, document)
        expect(seen).to include([ :delete, :content, document ])

        seen.clear
        post rivet_cms.content_type_documents_path(content_type), params: { slug: "fresh" }
        expect(seen).to include([ :write, :content, content_type ])
      end

      it "trash actions pass the trashed document" do
        document = entry
        delete rivet_cms.content_type_document_path(content_type, document)
        observe!

        patch rivet_cms.restore_content_type_document_path(content_type, document)
        expect(seen).to include([ :delete, :content, document ])
      end

      it "schema actions pass the type, field, and component" do
        field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
        component = create(:component, organization: organization)
        observe!

        patch rivet_cms.content_type_path(content_type), params: { content_type: { name: "Posts" } }
        expect(seen).to include([ :write, :schema, content_type ])

        patch rivet_cms.content_type_field_path(content_type, field), params: { field: { label: "Title" } }
        expect(seen).to include([ :write, :schema, field ])

        delete rivet_cms.component_path(component)
        expect(seen).to include([ :delete, :schema, component ])
      end

      it "removing a type with entries passes it to the content cascade too" do
        entry
        observe!

        delete rivet_cms.content_type_path(content_type)

        expect(seen).to include([ :delete, :schema, content_type ])
        expect(seen).to include([ :delete, :content, content_type ])
      end

      it "media and token actions pass the loaded record" do
        file = Tempfile.new([ "pic", ".png" ])
        file.binmode
        file.write("\x89PNG\r\n\x1a\n".b + "fake-image")
        file.rewind
        asset = MediaAsset.create!(organization: organization, file: Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "pic.png"))
        token = ApiToken.generate!(name: "t", scope: "published", organization: organization)
        observe!

        patch rivet_cms.media_asset_path(asset), params: { title: "x" }
        expect(seen).to include([ :write, :media, asset ])

        delete rivet_cms.api_token_path(token)
        expect(seen).to include([ :delete, :api, token ])
      end
    end

    describe "per-record decisions actually gate" do
      it "denies one entry while allowing its sibling" do
        blocked = entry("blocked")
        allowed = entry("allowed")
        RivetCms.can = ->(check) { check.record != blocked }

        patch rivet_cms.content_type_document_path(content_type, blocked), params: { values: {} }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("permission")

        patch rivet_cms.content_type_document_path(content_type, allowed), params: { values: {} }
        expect(response).to have_http_status(:found)
      end

      it "denies one type's entry list while allowing another's" do
        other = create(:content_type, slug: "notes", organization: organization)
        RivetCms.can = ->(check) { check.record != content_type }

        get rivet_cms.content_type_documents_path(content_type)
        expect(response).not_to have_http_status(:ok)

        get rivet_cms.content_type_documents_path(other)
        expect(response).to have_http_status(:ok)
      end

      it "denies publish per record" do
        document = entry
        RivetCms.can = ->(check) { !(check.action == :publish && check.record == document) }

        post rivet_cms.publish_content_type_document_path(content_type, document)

        expect(document.reload.published_revision_id).to be_nil
      end
    end

    describe "list surfaces hide what the record phase denies" do
      it "entry lists, the Content page, the dashboard, and the reference picker" do
        blocked = entry("blocked")
        entry("allowed")
        RivetCms.can = ->(check) { check.record != blocked }

        get rivet_cms.content_type_documents_path(content_type)
        expect(response.body).not_to include("blocked")
        expect(response.body).to include("allowed")

        get rivet_cms.content_path
        expect(response.body).not_to include("blocked")

        get rivet_cms.root_path
        expect(response.body).not_to include("blocked")

        get rivet_cms.edit_content_type_document_path(content_type, Document.find_by!(slug: "allowed"))
        options = CGI.unescapeHTML(response.body)[/"reference_options":\[[^\]]*\]/]
        expect(options).not_to include("blocked")
      end

      it "the entry trash" do
        hidden = entry("sneaky-entry")
        delete rivet_cms.content_type_document_path(content_type, hidden)
        RivetCms.can = ->(check) { check.record != hidden }

        get rivet_cms.trash_content_type_documents_path(content_type)

        page = CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1])
        expect(JSON.parse(page)["props"]["documents"]).to be_empty
      end

      it "type, component, and token lists" do
        secret_type = create(:content_type, slug: "secrets", organization: organization)
        component = create(:component, name: "SecretBlock", organization: organization)
        token = ApiToken.generate!(name: "secret-token", scope: "published", organization: organization)
        RivetCms.can = ->(check) { ![ secret_type, component, token ].include?(check.record) }

        get rivet_cms.content_types_path
        expect(response.body).not_to include("secrets")

        get rivet_cms.components_path
        expect(response.body).not_to include("SecretBlock")

        get rivet_cms.api_tokens_path
        expect(response.body).not_to include("secret-token")
      end

      it "hides a whole type from the Content page filter and the dashboard" do
        secret_type = create(:content_type, slug: "secrets", organization: organization)
        RivetCms.can = ->(check) { check.record != secret_type }

        get rivet_cms.content_path
        expect(response.body).not_to include("secrets")

        get rivet_cms.root_path
        expect(response.body).not_to include("secrets")
      end

      it "denying a type hides its entries from cross-type surfaces too" do
        secret_type = create(:content_type, slug: "secrets", organization: organization)
        secret_entry = create(:document, slug: "classified-entry", content_type: secret_type, organization: organization)
        secret_entry.update!(draft_revision: create(:document_revision, document: secret_entry, state: :draft))
        mine = entry("mine")
        RivetCms.can = ->(check) { check.record != secret_type }

        get rivet_cms.content_path
        expect(response.body).not_to include("classified-entry")

        get rivet_cms.root_path
        expect(response.body).not_to include("classified-entry")

        get rivet_cms.edit_content_type_document_path(content_type, mine)
        options = CGI.unescapeHTML(response.body)[/"reference_options":\[[^\]]*\]/]
        expect(options).not_to include("classified-entry")
      end

      it "an allowed type referencing a denied one keeps the spec valid and unleaked" do
        secret_type = create(:content_type, slug: "secrets", organization: organization)
        create(:field, :reference, key: "secret_ref", content_type: content_type, organization: organization,
               config: { "content_type_id" => secret_type.id })
        RivetCms.can = ->(check) { check.record != secret_type }

        get rivet_cms.api_openapi_path

        spec = JSON.parse(response.body)
        expect(response.body).not_to include("secrets")
        refs = response.body.scan(%r{#/components/schemas/(\w+)}).flatten.uniq
        expect(refs - spec.dig("components", "schemas").keys).to be_empty
      end

      it "a denied component embedded in an allowed type stays opaque" do
        component = create(:component, name: "SecretBlock", organization: organization)
        create(:field, :string, key: "internal_notes", component: component, content_type: nil, organization: organization)
        create(:field, key: "block", field_type: "component", content_type: content_type, organization: organization,
               config: { "component_id" => component.id })
        RivetCms.can = ->(check) { check.record != component }

        get rivet_cms.api_openapi_path
        expect(response.body).not_to include("internal_notes")

        get rivet_cms.content_type_path(content_type)
        embeddable = CGI.unescapeHTML(response.body)[/"embeddable_components":\[[^\]]*\]/]
        expect(embeddable).not_to include("SecretBlock")
      end

      it "schema-denied types leave the API docs, the OpenAPI spec, and reference targets" do
        secret_type = create(:content_type, slug: "secrets", organization: organization)
        component = create(:component, organization: organization)
        RivetCms.can = ->(check) { check.record != secret_type }

        get rivet_cms.api_docs_path
        expect(response.body).not_to include("secrets")

        get rivet_cms.api_openapi_path
        expect(response.body).not_to include("secrets")

        get rivet_cms.content_type_path(content_type)
        targets = CGI.unescapeHTML(response.body)[/"reference_targets":\[[^\]]*\]/]
        expect(targets).not_to include("secrets")

        get rivet_cms.component_path(component)
        targets = CGI.unescapeHTML(response.body)[/"reference_targets":\[[^\]]*\]/]
        expect(targets).not_to include("secrets")
      end
    end

    describe "parent denials compose to children on direct URLs" do
      it "a denied type's entry cannot be opened, edited, or published directly" do
        document = entry
        RivetCms.can = ->(check) { check.record != content_type }

        get rivet_cms.edit_content_type_document_path(content_type, document)
        expect(response).not_to have_http_status(:ok)

        patch rivet_cms.content_type_document_path(content_type, document), params: { values: {} }
        expect(response).to have_http_status(:forbidden)

        post rivet_cms.publish_content_type_document_path(content_type, document)
        expect(response).to have_http_status(:forbidden)
        expect(document.reload.published_revision_id).to be_nil
      end

      it "an owner-level delete denial blocks field deletion, verb-matched" do
        field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
        RivetCms.can = ->(check) { !(check.action == :delete && check.record == content_type) }

        delete rivet_cms.content_type_field_path(content_type, field)

        expect(response).to have_http_status(:forbidden)
        expect(Field.exists?(field.id)).to be true
      end

      it "field deletion needs owner delete, not owner write" do
        field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
        RivetCms.can = ->(check) { !(check.action == :write && check.record == content_type) }

        delete rivet_cms.content_type_field_path(content_type, field)

        expect(Field.exists?(field.id)).to be false
      end

      it "a denied type's field cannot be updated directly" do
        field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
        RivetCms.can = ->(check) { check.record != content_type }

        patch rivet_cms.content_type_field_path(content_type, field), params: { field: { label: "Renamed" } }

        expect(response).to have_http_status(:forbidden)
        expect(field.reload.label).not_to eq("Renamed")
      end
    end

    describe "every gate keeps both phases" do
      it "a recordless delete-content veto still blocks removing a type with entries" do
        entry
        RivetCms.can = ->(check) { !(check.record.nil? && check.action == :delete && check.resource == :content) }

        delete rivet_cms.content_type_path(content_type)

        expect(ContentType.find_by(id: content_type.id)).to be_present
      end

      it "layout reordering checks the owner in the record phase" do
        create(:field, :string, key: "title", content_type: content_type, organization: organization)
        RivetCms.can = ->(check) { check.record != content_type }

        post rivet_cms.update_layout_content_type_fields_path(content_type), params: { rows: [] }

        expect(response).to have_http_status(:forbidden)
      end

      it "layout reordering checks every field it moves, not just the owner" do
        movable = create(:field, :string, key: "movable", content_type: content_type, organization: organization)
        pinned = create(:field, :string, key: "pinned", content_type: content_type, organization: organization)
        before_rows = [ pinned.reload.row, pinned.position ]
        RivetCms.can = ->(check) { check.record != pinned }

        post rivet_cms.update_layout_content_type_fields_path(content_type),
             params: { rows: [ [ pinned.id ], [ movable.id ] ] }, as: :json

        expect(response).to have_http_status(:forbidden)
        expect([ pinned.reload.row, pinned.position ]).to eq(before_rows)
      end

      it "pairing checks both fields it mutates" do
        left = create(:field, :string, key: "left", content_type: content_type, organization: organization, width: "half")
        right = create(:field, :string, key: "right", content_type: content_type, organization: organization, width: "half")
        RivetCms.can = ->(check) { check.record != right }

        patch rivet_cms.pair_content_type_field_path(content_type, left), params: { pair_with: right.id }

        expect(response).to have_http_status(:forbidden)
        expect(left.reload.paired?).to be false
      end
    end

    it "the recordless phase still fails fast before anything loads" do
      document = entry
      RivetCms.can = ->(check) { !check.record.nil? }

      patch rivet_cms.content_type_document_path(content_type, document), params: { values: {} }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("permission")
    end
  end
end
