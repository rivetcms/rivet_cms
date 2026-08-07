require 'rails_helper'

module RivetCms
  RSpec.describe "Sidebar navigation", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    def nav
      page = response.body[/data-page="([^"]*)"/, 1]
      JSON.parse(CGI.unescapeHTML(page))["props"]["nav"]
    end

    def item_keys
      nav.flat_map { |group| group["items"] }.map { |item| item["key"] }
    end

    before { organization }

    it "serves the full sidebar under the default allow-all policy" do
      get rivet_cms.root_path

      expect(nav.map { |group| group["section"] }).to eq([ "", "Manage", "Deliver" ])
      expect(item_keys).to eq(%w[dashboard content content_types components media api api_tokens])
    end

    it "drops items a user cannot reach" do
      RivetCms.can = ->(check) { !(check.action == :read && check.resource == :content) }

      get rivet_cms.root_path

      expect(item_keys).not_to include("content")
      expect(item_keys).to include("content_types", "media", "api")
    end

    it "drops a whole section when every item in it is denied" do
      RivetCms.can = ->(check) { check.resource != :api }

      get rivet_cms.root_path

      expect(nav.map { |group| group["section"] }).not_to include("Deliver")
    end

    it "shows only the dashboard under a deny-all policy" do
      RivetCms.can = ->(_check) { false }

      get rivet_cms.root_path

      expect(item_keys).to eq(%w[dashboard])
    end

    it "serves a registered item with its lambda path resolved" do
      Navigation.register :audit, label: "Audit Log", section: "Manage",
                          requires: [ :read, :content ], path: -> { root_path }, position: 55

      get rivet_cms.root_path

      manage = nav.find { |group| group["section"] == "Manage" }
      audit = manage["items"].find { |item| item["key"] == "audit" }
      expect(audit["label"]).to eq("Audit Log")
      expect(audit["path"]).to eq(rivet_cms.root_path)
      expect(manage["items"].map { |item| item["key"] }).to eq(%w[content content_types components media audit])
    end

    it "a registered item honors its requires gate" do
      Navigation.register :audit, label: "Audit Log", section: "Manage",
                          requires: [ :read, :audit ], path: "/audit"
      RivetCms.can = ->(check) { check.resource != :audit }

      get rivet_cms.root_path

      expect(item_keys).not_to include("audit")
    end

    it "a new section appears where its lowest-position item falls" do
      Navigation.register :pro_thing, label: "Pro Thing", section: "Pro", path: "/pro", position: 80

      get rivet_cms.root_path

      expect(nav.map { |group| group["section"] }).to eq([ "", "Manage", "Deliver", "Pro" ])
    end

    it "emits registered admin bundles after the core tags" do
      RivetCms.register_admin_script("rivet_cms_pro")
      RivetCms.register_admin_stylesheet("rivet_cms_pro")

      get rivet_cms.root_path

      core = response.body.index('src="/assets/rivet_cms')
      pro = response.body.index('src="/assets/rivet_cms_pro')
      expect(pro).to be > core
      expect(response.body).to match(/rivet_cms_pro[^"]*\.css/)
    end

    it "skips and logs an unresolvable bundle instead of failing every page" do
      RivetCms.register_admin_script("no_such_bundle")
      allow(Rails.logger).to receive(:error)

      get rivet_cms.root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("no_such_bundle")
      expect(Rails.logger).to have_received(:error).with(/no_such_bundle/)
    end

    it "emits no extension tags when nothing is registered" do
      get rivet_cms.root_path

      expect(response.body).not_to include("rivet_cms_pro")
    end
  end
end
