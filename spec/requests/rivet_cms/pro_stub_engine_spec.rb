require 'rails_helper'

# The seam capstone: every assertion here goes through ProStub, a real second
# engine loaded at boot (spec/pro_stub), rather than poking the registries
# directly. If this file passes, a Pro gem can attach to CE without CE
# knowing it exists.
module RivetCms
  RSpec.describe "Pro stub engine", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    def nav
      page = response.body[/data-page="([^"]*)"/, 1]
      JSON.parse(CGI.unescapeHTML(page))["props"]["nav"]
    end

    def draft_for(slug)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft
    end

    before do
      organization
      ProStub.install!
      ProStub.received.clear
      ProStub.pruned.clear
    end

    it "serves its admin page through the shared layout with its bundle after core's" do
      get rivet_cms.pro_stub_panel_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ProStub/Panel")
      expect(response.body).to include("hello from the pro stub")

      core = response.body.index('src="/assets/rivet_cms-')
      pro = response.body.index('src="/assets/rivet_cms_pro-')
      expect(core).to be_present
      expect(pro).to be > core
      expect(response.body).to match(/rivet_cms_pro[^"]*\.css/)
    end

    it "appears in the sidebar as its own section, linking to its route" do
      get rivet_cms.root_path

      pro_section = nav.find { |group| group["section"] == "Pro" }
      expect(pro_section).to be_present
      item = pro_section["items"].first
      expect(item["label"]).to eq("Pro Panel")
      expect(item["path"]).to eq(rivet_cms.pro_stub_panel_path)
    end

    it "is hidden and unreachable when the policy denies its resource" do
      RivetCms.can = ->(check) { check.resource != :pro_panel }

      get rivet_cms.root_path
      expect(nav.map { |group| group["section"] }).not_to include("Pro")

      get rivet_cms.pro_stub_panel_path
      expect(response).not_to have_http_status(:ok)
      expect(flash[:alert]).to include("permission")
    end

    it "hears retention pruning through the prune hook" do
      RivetCms.revision_retention = 0
      draft = draft_for("pruned-entry")
      first = draft.publish!
      draft = first.document.reload.draft_revision
      draft.publish!

      expect(ProStub.pruned).to eq([ first.id ])
      expect(DocumentRevision.exists?(first.id)).to be false
    end

    # The publish hook fires after the outermost commit, which transactional
    # fixtures never perform, so this group commits for real. Nothing here is
    # covered elsewhere: every other spec exercises Hooks.run directly.
    describe "across a real commit" do
      self.use_transactional_tests = false

      after do
        Organization.find_by(domain: "localhost")&.destroy
      end

      it "hears the publish hook with the published snapshot" do
        draft = draft_for("committed-entry")

        draft.publish!

        expect(ProStub.received.size).to eq(1)
        snapshot = ProStub.received.first
        expect(snapshot.id).to eq(draft.document.reload.published_revision_id)
        expect(snapshot.state).to eq("published")
      end
    end
  end
end
