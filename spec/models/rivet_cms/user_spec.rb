require 'rails_helper'

module RivetCms
  RSpec.describe User, type: :model do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    def build_user(**attrs)
      described_class.new({ name: "Jane", email: "jane@example.com", password: "supersecret", organization: organization }.merge(attrs))
    end

    it "is valid with name, email, and password" do
      expect(build_user).to be_valid
    end

    it "normalizes email case and whitespace" do
      user = build_user(email: "  Jane@Example.COM ")
      user.valid?
      expect(user.email).to eq("jane@example.com")
    end

    it "rejects duplicate emails case-insensitively within the organization" do
      build_user.save!
      dup = build_user(email: "JANE@example.com")
      expect(dup).not_to be_valid
    end

    it "rejects malformed emails" do
      expect(build_user(email: "nope")).not_to be_valid
    end

    it "rejects short passwords but allows none at all (pending invite)" do
      expect(build_user(password: "short")).not_to be_valid
      pending_user = build_user(password: nil)
      expect(pending_user).to be_valid
      expect(pending_user.pending?).to be(true)
      expect(pending_user.can_sign_in?).to be(false)
    end

    it "rejects passwords past BCrypt's 72-byte limit rather than truncating" do
      expect(build_user(password: "a" * 72)).to be_valid
      expect(build_user(password: "a" * 73)).not_to be_valid
      # A multibyte character can cross the boundary inside one glyph
      expect(build_user(password: "é" * 40)).not_to be_valid
    end

    it "reports status from active and pending" do
      expect(build_user.status).to eq("active")
      expect(build_user(password: nil).status).to eq("pending")
      expect(build_user(active: false).status).to eq("inactive")
    end

    describe "password setup tokens" do
      it "round-trips while valid and dies when the password changes" do
        user = build_user(password: nil).tap(&:save!)
        token = user.generate_token_for(:password_setup)

        expect(described_class.find_by_token_for(:password_setup, token)).to eq(user)

        user.update!(password: "chosen-by-user")
        expect(described_class.find_by_token_for(:password_setup, token)).to be_nil
      end

      it "expires" do
        user = build_user(password: nil).tap(&:save!)
        token = user.generate_token_for(:password_setup)

        travel 4.days do
          expect(described_class.find_by_token_for(:password_setup, token)).to be_nil
        end
      end
    end
  end
end
