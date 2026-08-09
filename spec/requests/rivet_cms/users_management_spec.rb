require 'rails_helper'

module RivetCms
  RSpec.describe "User management", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let!(:me) { User.create!(name: "Me", email: "me@example.com", password: "supersecret", organization: organization) }

    before do
      organization
      RivetCms.authenticate = RivetCms::DEFAULT_AUTHENTICATE
      post rivet_cms.login_path, params: { email: "me@example.com", password: "supersecret" }
    end

    def props
      page = response.body[/data-page="([^"]*)"/, 1]
      JSON.parse(CGI.unescapeHTML(page))["props"]
    end

    it "creates a pending user and shows the invite link exactly once" do
      post rivet_cms.users_path, params: { name: "New Person", email: "new@example.com" }

      user = User.find_by(email: "new@example.com")
      expect(user.pending?).to be(true)

      follow_redirect!
      expect(props["invite_link"]).to include("/join/")

      get rivet_cms.users_path
      expect(props["invite_link"]).to be_nil
    end

    it "the invite link it hands out actually works" do
      post rivet_cms.users_path, params: { name: "New Person", email: "new@example.com" }
      follow_redirect!
      link = props["invite_link"]
      delete rivet_cms.logout_path

      patch URI.parse(link).path, params: { password: "their-password" }

      expect(User.find_by(email: "new@example.com").can_sign_in?).to be(true)
    end

    it "updates name and email" do
      user = User.create!(name: "Temp", email: "temp@example.com", password: "supersecret", organization: organization)

      patch rivet_cms.user_path(user), params: { name: "Renamed", email: "renamed@example.com" }

      expect(user.reload.values_at(:name, :email)).to eq([ "Renamed", "renamed@example.com" ])
    end

    it "cannot deactivate your own account, even with others still active" do
      # A second active user exists, so the lockout guard would not fire here;
      # only the self-guard keeps me from deactivating myself
      User.create!(name: "Other", email: "other@example.com", password: "supersecret", organization: organization)

      patch rivet_cms.deactivate_user_path(me)

      expect(me.reload.active?).to be(true)
    end

    it "refuses to deactivate the last active user" do
      # me is the only active user; deactivating me would lock everyone out.
      # (Sequentially this is also the self-guard; the transaction lock is the
      # backstop for two admins deactivating each other concurrently.)
      patch rivet_cms.deactivate_user_path(me)

      expect(me.reload.active?).to be(true)
      expect(User.active.count).to eq(1)
    end

    it "a pending invitee does not count toward the last-active-user guard" do
      # me is the only user who can actually sign in; the invitee has no
      # password yet, so it must not let the guard treat someone as still
      # available when no one usable would remain
      User.create!(name: "Invited", email: "invited@example.com", organization: organization)

      patch rivet_cms.deactivate_user_path(me)

      expect(me.reload.active?).to be(true)
    end

    it "deactivation revokes sign-in and reactivation restores it" do
      user = User.create!(name: "Temp", email: "temp@example.com", password: "supersecret", organization: organization)

      patch rivet_cms.deactivate_user_path(user)
      expect(user.reload.can_sign_in?).to be(false)

      patch rivet_cms.reactivate_user_path(user)
      expect(user.reload.can_sign_in?).to be(true)
    end

    it "emits audit events for the lifecycle" do
      events = []
      RivetCms.on(:audit, key: :spec_users) { |event| events << event.action }
      user = User.create!(name: "Temp", email: "temp@example.com", password: "supersecret", organization: organization)

      post rivet_cms.users_path, params: { name: "A", email: "a@example.com" }
      patch rivet_cms.user_path(user), params: { name: "B" }
      patch rivet_cms.deactivate_user_path(user)
      patch rivet_cms.reactivate_user_path(user)

      expect(events).to eq(%w[user.created user.updated user.deactivated user.reactivated])
    end
  end
end
