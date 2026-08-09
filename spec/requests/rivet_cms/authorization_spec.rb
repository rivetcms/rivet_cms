require 'rails_helper'

module RivetCms
  RSpec.describe "Authorization seam", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    around do |example|
      original = RivetCms.can
      example.run
    ensure
      RivetCms.can = original
    end

    def deny(denied_action, denied_resource)
      RivetCms.can = ->(check) { !(check.action == denied_action && check.resource == denied_resource) }
    end

    # Browser page loads redirect with a flash; everything else gets a real 403
    def expect_denied
      if response.status == 403
        expect(response.body).to include("permission")
      else
        expect(response).to have_http_status(:found).or have_http_status(:see_other)
        expect(flash[:alert]).to include("permission")
      end
    end

    it "allows everything by default" do
      create(:content_type, organization: organization)
      get rivet_cms.content_types_path
      expect(response).to have_http_status(:ok)
    end

    it "passes an AccessCheck with user, action, resource, and organization" do
      seen = []
      RivetCms.can = ->(check) { seen << check; true }
      organization

      get rivet_cms.content_types_path

      check = seen.first
      expect(check).to be_a(AccessCheck)
      expect(check.user).to be_nil
      expect(check.action).to eq(:read)
      expect(check.resource).to eq(:schema)
      expect(check.organization).to eq(organization)
      expect(check.record).to be_nil
    end

    it "a raising policy denies and does not 500" do
      organization
      RivetCms.can = ->(_check) { raise "boom" }

      get rivet_cms.content_types_path
      expect_denied
    end

    it "denying schema writes blocks mutations but not reads or deletes-gated-separately" do
      content_type = create(:content_type, organization: organization)
      deny(:write, :schema)

      get rivet_cms.content_types_path
      expect(response).to have_http_status(:ok)

      post rivet_cms.content_types_path, params: { content_type: { name: "Blocked", slug: "blocked" } }
      expect_denied
      expect(ContentType.where(name: "Blocked")).to be_empty

      delete rivet_cms.content_type_path(content_type)
      expect(response).to have_http_status(:see_other)
      expect(ContentType.exists?(content_type.id)).to be false
    end

    it "denying schema deletes blocks destroy but not update" do
      content_type = create(:content_type, organization: organization)
      deny(:delete, :schema)

      delete rivet_cms.content_type_path(content_type)
      expect_denied
      expect(ContentType.exists?(content_type.id)).to be true
    end

    it "gates run before record loaders so missing ids do not 404 first" do
      organization
      RivetCms.can = ->(_check) { false }

      get rivet_cms.content_type_path("ctype_nonexistent")
      expect_denied
    end

    it "the editor is a read surface: content read opens it, content write alone does not" do
      content_type = create(:content_type, organization: organization)
      document = create(:document, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)

      deny(:write, :content)
      get rivet_cms.edit_content_type_document_path(content_type, document)
      expect(response).to have_http_status(:ok)

      deny(:read, :content)
      get rivet_cms.edit_content_type_document_path(content_type, document)
      expect_denied
    end

    it "publish and delete are distinct from content write" do
      content_type = create(:content_type, organization: organization)
      document = create(:document, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)

      deny(:publish, :content)
      post rivet_cms.publish_content_type_document_path(content_type, document)
      expect_denied
      expect(document.reload.published_revision_id).to be_nil

      deny(:delete, :content)
      delete rivet_cms.content_type_document_path(content_type, document)
      expect_denied
      expect(Document.exists?(document.id)).to be true
    end

    it "denying media writes blocks uploads with a JSON error" do
      organization
      deny(:write, :media)

      file = Tempfile.new([ "pic", ".png" ])
      file.binmode
      file.write("\x89PNG\r\n\x1a\n".b + "fake")
      file.rewind

      post rivet_cms.media_assets_path, params: { file: Rack::Test::UploadedFile.new(file.path, "image/png") },
                                        headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"].join).to include("permission")
      expect(MediaAsset.count).to eq(0)
    end

    it "minting a token requires content read, closing the preview escalation" do
      organization
      deny(:read, :content)

      post rivet_cms.api_tokens_path, params: { name: "Sneaky", scope: "preview" }
      expect_denied
      expect(ApiToken.count).to eq(0)
    end

    it "the API docs also require schema read" do
      organization
      deny(:read, :schema)

      get rivet_cms.api_docs_path
      expect_denied
      get rivet_cms.api_openapi_path
      expect_denied
    end

    it "the dashboard filters denied sections instead of leaking them" do
      content_type = create(:content_type, organization: organization, name: "SecretType")
      document = create(:document, slug: "secret-entry", content_type: content_type, organization: organization)
      RivetCms.can = ->(_check) { false }

      get rivet_cms.root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("secret-entry")
      expect(response.body).not_to include("SecretType")
      expect(response.body).not_to include("entry_count")
    end

    it "does not leak entry counts to schema-only readers" do
      content_type = create(:content_type, organization: organization)
      create(:document, content_type: content_type, organization: organization)
      deny(:read, :content)

      get rivet_cms.content_types_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("documents_count")
    end

    it "a denial from a page does not redirect back to that same page" do
      organization
      RivetCms.can = ->(_check) { false }

      get rivet_cms.content_types_path, headers: { "HTTP_REFERER" => rivet_cms.content_types_url }

      expect(response).to redirect_to(rivet_cms.root_path)
    end

    it "deleting a content type that owns entries also requires content delete" do
      content_type = create(:content_type, organization: organization)
      create(:document, content_type: content_type, organization: organization)
      deny(:delete, :content)

      delete rivet_cms.content_type_path(content_type)

      expect_denied
      expect(ContentType.exists?(content_type.id)).to be true
      expect(Document.count).to eq(1)
    end

    it "an empty content type deletes without content delete" do
      content_type = create(:content_type, organization: organization)
      deny(:delete, :content)

      delete rivet_cms.content_type_path(content_type)

      expect(ContentType.exists?(content_type.id)).to be false
    end

    it "denied writes fail loudly for API clients whose Accept header looks browser-like" do
      organization
      RivetCms.can = ->(_check) { false }

      post rivet_cms.media_assets_path, params: { name: "x" },
                                        headers: { "Accept" => "application/json, text/plain, */*" }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"].join).to include("permission")
    end

    it "a policy returning a truthy non-boolean denies" do
      organization
      RivetCms.can = ->(_check) { [] }

      get rivet_cms.content_types_path
      expect_denied
    end

    it "content-only readers do not receive schema descriptions or management paths" do
      create(:content_type, organization: organization, description: "Internal schema notes")
      deny(:read, :schema)

      get rivet_cms.content_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Internal schema notes")
      expect(response.body).not_to include("update_layout")
    end

    it "field deletion is a schema delete, not a schema write" do
      content_type = create(:content_type, organization: organization)
      field = create(:field, :string, content_type: content_type, organization: organization)
      deny(:delete, :schema)

      delete rivet_cms.content_type_field_path(content_type, field)

      expect_denied
      expect(field.reload.deleted_at).to be_nil
    end

    it "denies every admin route under a deny-all policy" do
      organization
      RivetCms.can = ->(_check) { false }
      open_routes = [ "/", "/api/:content_type_slug", "/api/:content_type_slug/:slug" ]
      # Built-in auth surfaces 404 under host auth (this suite's mode); their
      # gating is covered by the built-in auth specs
      builtin_only = [ "/login", "/logout", "/setup", "/join/:token",
                       "/users", "/users/:id", "/users/:id/deactivate",
                       "/users/:id/reactivate", "/users/:id/reset_link" ]
      open_routes += builtin_only

      swept = 0
      RivetCms::Engine.routes.routes.each do |route|
        spec = route.path.spec.to_s.sub("(.:format)", "")
        next if open_routes.include?(spec)

        verb = route.verb.to_s.split("|").first&.downcase
        next if verb.blank?

        path = spec.gsub(/:[a-z_]+/, "1")
        send(verb, path)
        denied = (response.status == 403 && response.body.include?("permission")) ||
                 (response.status == 302 && flash[:alert].to_s.include?("permission"))
        expect(denied).to be(true), "expected #{verb.upcase} #{spec} to be denied, got #{response.status}"
        swept += 1
      end
      expect(swept).to be > 20
    end
  end
end
