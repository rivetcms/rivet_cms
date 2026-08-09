require 'rails_helper'

module RivetCms
  RSpec.describe "Built-in authentication", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    before do
      organization
      RivetCms.authenticate = RivetCms::DEFAULT_AUTHENTICATE # enter built-in mode
    end

    def create_user(email: "user@example.com", password: "supersecret", **attrs)
      User.create!({ name: "A User", email: email, password: password, organization: organization }.merge(attrs))
    end

    def sign_in(email:, password: "supersecret")
      post rivet_cms.login_path, params: { email: email, password: password }
    end

    describe "first run" do
      it "walks setup: visit, create the owner, land signed in" do
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.setup_path)

        post rivet_cms.setup_path, params: { name: "Nathan", email: "nathan@example.com", password: "supersecret" }
        expect(response).to redirect_to(rivet_cms.root_path)
        expect(User.count).to eq(1)

        get rivet_cms.root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("nathan@example.com")
      end

      it "refuses a blank password instead of creating a passwordless owner" do
        post rivet_cms.setup_path, params: { name: "Nathan", email: "nathan@example.com", password: "" }

        expect(User.count).to eq(0)
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.setup_path)
      end

      it "requires the logged setup code outside development and test" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        post rivet_cms.setup_path, params: { name: "Intruder", email: "evil@example.com", password: "supersecret" }
        expect(User.count).to eq(0)

        post rivet_cms.setup_path, params: { name: "Nathan", email: "nathan@example.com",
                                             password: "supersecret", setup_code: RivetCms.setup_code }
        expect(User.count).to eq(1)
      ensure
        RivetCms.setup_code = nil
      end

      it "closes setup the moment a user exists" do
        create_user

        get rivet_cms.setup_path
        expect(response).to redirect_to(rivet_cms.login_path)

        post rivet_cms.setup_path, params: { name: "X", email: "x@example.com", password: "supersecret" }
        expect(User.where(email: "x@example.com")).to be_empty
      end
    end

    describe "sessions" do
      it "signs in with valid credentials and out again" do
        create_user
        sign_in(email: "user@example.com")
        expect(response).to redirect_to(rivet_cms.root_path)

        get rivet_cms.root_path
        expect(response).to have_http_status(:ok)

        delete rivet_cms.logout_path
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      end

      it "gives one identical message for wrong password and unknown email" do
        create_user
        sign_in(email: "user@example.com", password: "wrong")
        wrong_password = response.headers["Location"]
        sign_in(email: "ghost@example.com")
        expect(response.headers["Location"]).to eq(wrong_password)

        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      end

      it "refuses pending and deactivated users" do
        create_user(email: "pending@example.com", password: nil)
        create_user(email: "inactive@example.com", active: false)

        sign_in(email: "pending@example.com", password: "")
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)

        sign_in(email: "inactive@example.com")
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      end

      it "throttles repeated attempts from one IP" do
        # Throttling relies on a real cache; the test env uses null_store
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user

        SessionsController::LOGIN_ATTEMPT_LIMIT.times do
          sign_in(email: "user@example.com", password: "wrong")
        end
        # Even the correct password is refused once the window is full
        sign_in(email: "user@example.com")
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      ensure
        Rails.cache = original
      end

      it "a successful login does not reset another account's attempt counter" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user(email: "target@example.com")
        create_user(email: "attacker@example.com")
        limit = SessionsController::LOGIN_ATTEMPT_LIMIT

        # Guess the target up to one short of the limit
        (limit - 1).times { sign_in(email: "target@example.com", password: "wrong") }
        # Sign into a different account: clears this IP and that account only,
        # then sign back out so its session cannot mask the assertion
        sign_in(email: "attacker@example.com")
        delete rivet_cms.logout_path
        # The target's own counter survived, so one more guess locks it even
        # though the IP counter was just reset by the attacker's success
        sign_in(email: "target@example.com", password: "wrong")

        # Now even the correct target password is refused: account bucket full
        sign_in(email: "target@example.com")
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      ensure
        Rails.cache = original
      end

      it "a success releases only its own IP reservation, not prior IP failures" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user
        limit = SessionsController::LOGIN_ATTEMPT_LIMIT
        ip = { "REMOTE_ADDR" => "9.9.9.9" }

        # Fail against other accounts, then sign into my own; the success must
        # not wipe the IP's accumulated failures
        (limit - 1).times { |i| post rivet_cms.login_path, params: { email: "ghost#{i}@example.com", password: "wrong" }, headers: ip }
        post rivet_cms.login_path, params: { email: "user@example.com", password: "supersecret" }, headers: ip
        delete rivet_cms.logout_path, headers: ip

        # Two more failures push the IP over the limit; if the success had
        # reset it, these would be well under limit
        post rivet_cms.login_path, params: { email: "ghost-a@example.com", password: "wrong" }, headers: ip
        post rivet_cms.login_path, params: { email: "ghost-b@example.com", password: "wrong" }, headers: ip
        post rivet_cms.login_path, params: { email: "user@example.com", password: "supersecret" }, headers: ip
        get rivet_cms.root_path, headers: ip
        expect(response).to redirect_to(rivet_cms.login_path)
      ensure
        Rails.cache = original
      end

      it "a blocked IP does not increment account counters, so it cannot lock a victim" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user(email: "victim@example.com")
        limit = SessionsController::LOGIN_ATTEMPT_LIMIT
        attacker = { "REMOTE_ADDR" => "6.6.6.6" }

        # Lock the attacker IP on nonexistent accounts, then spray the victim
        # from it; those rejected-at-IP requests must not touch the victim's
        # account counter
        (limit + 1).times { |i| post rivet_cms.login_path, params: { email: "ghost#{i}@example.com", password: "wrong" }, headers: attacker }
        20.times { post rivet_cms.login_path, params: { email: "victim@example.com", password: "wrong" }, headers: attacker }

        # The victim signs in from a clean IP; their account was never bumped
        post rivet_cms.login_path, params: { email: "victim@example.com", password: "supersecret" }, headers: { "REMOTE_ADDR" => "7.7.7.7" }
        get rivet_cms.root_path, headers: { "REMOTE_ADDR" => "7.7.7.7" }
        expect(response).to have_http_status(:ok)
      ensure
        Rails.cache = original
      end

      it "a locked account does not drain the IP budget of the requests hitting it" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user(email: "victim@example.com")
        create_user(email: "other@example.com")
        limit = SessionsController::LOGIN_ATTEMPT_LIMIT

        # Lock the victim account from one IP
        (limit + 1).times { post rivet_cms.login_path, params: { email: "victim@example.com", password: "wrong" }, headers: { "REMOTE_ADDR" => "1.1.1.1" } }
        # Spray the locked account from a second IP; each account-rejected
        # request must release its own IP reservation
        20.times { post rivet_cms.login_path, params: { email: "victim@example.com", password: "wrong" }, headers: { "REMOTE_ADDR" => "2.2.2.2" } }

        # A different account from that second IP still works: it was not locked
        post rivet_cms.login_path, params: { email: "other@example.com", password: "supersecret" }, headers: { "REMOTE_ADDR" => "2.2.2.2" }
        get rivet_cms.root_path, headers: { "REMOTE_ADDR" => "2.2.2.2" }
        expect(response).to have_http_status(:ok)
      ensure
        Rails.cache = original
      end

      it "does not resurrect an expired reservation as a permanent counter" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        create_user
        ip_key = "rivet_cms:login_attempts:ip:5.5.5.5"
        # Simulate the IP key expiring during the BCrypt comparison: drop it
        # exactly when authenticate runs, then let the login succeed
        allow_any_instance_of(User).to receive(:authenticate).and_wrap_original do |m, *args|
          Rails.cache.delete(ip_key)
          m.call(*args)
        end

        post rivet_cms.login_path, params: { email: "user@example.com", password: "supersecret" },
                                   headers: { "REMOTE_ADDR" => "5.5.5.5" }

        # The release must not have recreated a lingering (non-expiring) entry
        expect(Rails.cache.read(ip_key)).to be_nil
      ensure
        Rails.cache = original
      end

      it "keeps account throttle counters separate across tenants" do
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        tenant_b = Organization.create!(name: "B", domain: "tenantb.example.com", subdomain: "b")
        create_user(email: "same@example.com")
        User.create!(name: "B user", email: "same@example.com", password: "supersecret", organization: tenant_b)
        limit = SessionsController::LOGIN_ATTEMPT_LIMIT

        # Exhaust the account counter in tenant A (distinct IP so the shared IP
        # counter does not confound the account-scoping we are testing)
        (limit + 1).times do
          post rivet_cms.login_path, params: { email: "same@example.com", password: "wrong" },
                                     headers: { "REMOTE_ADDR" => "10.0.0.1" }
        end

        # Same email in tenant B, different IP: a separate counter, so this
        # succeeds. If counters were shared by email it would be locked out.
        post rivet_cms.login_path, params: { email: "same@example.com", password: "supersecret" },
                                   headers: { "HTTP_HOST" => "tenantb.example.com", "REMOTE_ADDR" => "10.0.0.2" }
        get rivet_cms.root_path, headers: { "HTTP_HOST" => "tenantb.example.com", "REMOTE_ADDR" => "10.0.0.2" }
        expect(response).to have_http_status(:ok)

        # Tenant A is still locked, so B's success did not touch A's counter
        post rivet_cms.login_path, params: { email: "same@example.com", password: "supersecret" },
                                   headers: { "REMOTE_ADDR" => "10.0.0.1" }
        get rivet_cms.root_path, headers: { "REMOTE_ADDR" => "10.0.0.1" }
        expect(response).to redirect_to(rivet_cms.login_path)
      ensure
        Rails.cache = original
      end

      it "revokes existing sessions when the password changes" do
        user = create_user
        sign_in(email: "user@example.com")
        get rivet_cms.root_path
        expect(response).to have_http_status(:ok)

        # A second, independent session changes the password
        user.update!(password: "a-brand-new-password")

        # The original session (this one) is now invalid
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      end
    end

    describe "no roles in CE" do
      it "every authenticated user can do everything, including manage users" do
        create_user
        sign_in(email: "user@example.com")

        # Full sidebar, nothing hidden
        get rivet_cms.root_path
        nav = JSON.parse(CGI.unescapeHTML(response.body[/data-page="([^"]*)"/, 1]))["props"]["nav"]
        keys = nav.flat_map { |g| g["items"] }.map { |i| i["key"] }
        expect(keys).to include("content", "content_types", "media", "trash", "users", "api_tokens")

        # Schema, the API domain, and user management are all reachable
        post rivet_cms.content_types_path, params: { content_type: { name: "Posts", slug: "posts" } }
        expect(ContentType.where(slug: "posts")).to be_present
        get rivet_cms.users_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "invitation links" do
      it "sets the password, signs in, and burns the token" do
        pending_user = create_user(email: "invited@example.com", password: nil)
        token = pending_user.generate_token_for(:password_setup)

        get rivet_cms.invitation_path(token)
        expect(response).to have_http_status(:ok)

        patch rivet_cms.invitation_path(token), params: { password: "chosen-by-them" }
        expect(response).to redirect_to(rivet_cms.root_path)
        expect(pending_user.reload.can_sign_in?).to be(true)

        get rivet_cms.root_path
        expect(response).to have_http_status(:ok)

        # The token embedded the old salt; it is dead now
        delete rivet_cms.logout_path
        get rivet_cms.invitation_path(token)
        expect(response).to redirect_to(rivet_cms.login_path)
      end

      it "refuses a blank password instead of signing in a pending user" do
        pending_user = create_user(email: "blank@example.com", password: nil)
        token = pending_user.generate_token_for(:password_setup)

        patch rivet_cms.invitation_path(token), params: { password: "" }

        # The guard bounces back to the form; it does not "succeed" and sign in
        expect(response).to redirect_to(rivet_cms.invitation_path(token))
        expect(pending_user.reload.pending?).to be(true)
        # And the session layer independently keeps the pending user out
        get rivet_cms.root_path
        expect(response).to redirect_to(rivet_cms.login_path)
      end

      it "refuses expired links and deactivated users" do
        pending_user = create_user(email: "late@example.com", password: nil)
        token = pending_user.generate_token_for(:password_setup)

        travel 4.days do
          get rivet_cms.invitation_path(token)
          expect(response).to redirect_to(rivet_cms.login_path)
        end

        pending_user.update!(active: false)
        fresh = pending_user.generate_token_for(:password_setup)
        get rivet_cms.invitation_path(fresh)
        expect(response).to redirect_to(rivet_cms.login_path)
      end
    end

    describe "host mode" do
      it "404s every built-in surface when the host wired its own auth" do
        RivetCms.authenticate = ->(_c) { true }

        get rivet_cms.login_path
        expect(response).to have_http_status(:not_found)
        get rivet_cms.setup_path
        expect(response).to have_http_status(:not_found)
        get rivet_cms.users_path
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
