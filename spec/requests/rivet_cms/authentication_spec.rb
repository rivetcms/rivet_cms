require 'rails_helper'

module RivetCms
  RSpec.describe "Authentication delegation", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    describe "with a denying authenticate lambda" do
      before { RivetCms.authenticate = ->(controller) { controller.head :unauthorized } }

      it "blocks admin routes" do
        get rivet_cms.root_path
        expect(response).to have_http_status(:unauthorized)

        get rivet_cms.content_types_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "leaves the public read API open" do
        RivetCms.public_api = true
        content_type
        get rivet_cms.content_index_path("articles")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "with a redirecting authenticate lambda" do
      it "respects a response the lambda made itself" do
        RivetCms.authenticate = ->(controller) { controller.redirect_to "/host/login" }
        get rivet_cms.root_path
        expect(response).to redirect_to("/host/login")
      end
    end

    describe "when the lambda returns falsy without halting (fail closed)" do
      before { RivetCms.authenticate = ->(_controller) { false } }

      it "403s a full page load when no login_path is set" do
        get rivet_cms.root_path
        expect(response).to have_http_status(:forbidden)
      end

      it "redirects a full page load to login_path when set" do
        RivetCms.login_path = "/host/login"
        get rivet_cms.root_path
        expect(response).to redirect_to("/host/login")
      end

      it "leaves the public read API open" do
        RivetCms.public_api = true
        content_type
        get rivet_cms.content_index_path("articles")
        expect(response).to have_http_status(:ok)
      end
    end

    describe "with a configured current_user" do
      let(:jane) { ::User.create!(name: "Jane Editor", email: "jane@example.com") }

      before do
        organization
        RivetCms.current_user = ->(_controller) { jane }
      end

      it "stamps drafts with the polymorphic author and cached name" do
        post rivet_cms.content_type_documents_path(content_type), params: { slug: "hello" }

        draft = Document.last.draft_revision
        expect(draft.author_type).to eq("User")
        expect(draft.author_id).to eq(jane.id)
        expect(draft.author_name).to eq("Jane Editor")
      end

      it "updates the author to the last editor" do
        post rivet_cms.content_type_documents_path(content_type), params: { slug: "hello" }
        document = Document.last

        bob = ::User.create!(name: "Bob Writer", email: "bob@example.com")
        RivetCms.current_user = ->(_controller) { bob }
        patch rivet_cms.content_type_document_path(content_type, document), params: { values: {} }

        expect(document.draft_revision.reload.author_name).to eq("Bob Writer")
      end

      it "carries authorship into the published snapshot" do
        create(:field, :string, key: "title", content_type: content_type, organization: organization)
        post rivet_cms.content_type_documents_path(content_type), params: { slug: "hello", values: { title: "Hi" } }
        document = Document.last

        post rivet_cms.publish_content_type_document_path(content_type, document)

        published = document.reload.published_revision
        expect(published.author_name).to eq("Jane Editor")
        expect(published.author).to eq(jane)
      end

      it "shares identity and auth paths with the frontend" do
        RivetCms.login_path = "/signin"
        RivetCms.logout_path = "/signout"

        get rivet_cms.root_path
        expect(response.body).to include("Jane Editor")
        expect(response.body).to include("jane@example.com")
        expect(response.body).to include("/signout")
      end
    end

    describe "with the dummy app's session auth" do
      before do
        organization
        # Mirror the dummy initializer via the session (parent_controller cannot
        # be re-parented once the class is loaded, so read the session directly).
        # Return truthy to allow; the engine redirects to login_path on denial.
        RivetCms.authenticate = ->(c) { c.session[:user_id].present? }
        RivetCms.current_user = ->(c) { ::User.find_by(id: c.session[:user_id]) }
        RivetCms.login_path = "/host/login"
        RivetCms.logout_path = "/host/logout"
      end

      it "walks the full login/use/logout cycle" do
        get rivet_cms.root_path
        expect(response).to redirect_to("/host/login")

        post "/host/login", params: { email: "dev@example.com" }
        expect(response).to redirect_to("/")

        get rivet_cms.root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("dev@example.com")

        delete "/host/logout"
        get rivet_cms.root_path
        expect(response).to redirect_to("/host/login")
      end
    end

    it "shares a null auth prop when no current_user is configured" do
      organization
      get rivet_cms.root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("&quot;auth&quot;:null")
    end
  end
end
