require 'rails_helper'

module RivetCms
  RSpec.describe ApiToken, type: :model do
    let(:organization) { create(:organization) }

    describe ".generate!" do
      it "returns the plaintext once and stores only its digest" do
        token = described_class.generate!(name: "CI", scope: :published, organization: organization)

        expect(token.plaintext).to be_present
        expect(token.token_digest).to eq(described_class.digest(token.plaintext))
        expect(token.token_last4).to eq(token.plaintext.last(4))
        expect(described_class.find(token.id).plaintext).to be_nil # not persisted
      end
    end

    describe ".authenticate" do
      it "finds a token by its raw secret" do
        token = described_class.generate!(name: "CI", organization: organization)
        expect(described_class.authenticate(token.plaintext)).to eq(token)
      end

      it "returns nil for an unknown or blank secret" do
        expect(described_class.authenticate("nope")).to be_nil
        expect(described_class.authenticate(nil)).to be_nil
      end

      it "returns nil for an expired token" do
        token = described_class.generate!(name: "CI", organization: organization, expires_at: 1.hour.ago)
        expect(described_class.authenticate(token.plaintext)).to be_nil
      end
    end

    describe "scopes and validation" do
      it "defaults to the published scope" do
        expect(build(:api_token).scope).to eq("published")
      end

      it "requires a unique digest" do
        token = create(:api_token, organization: organization)
        dup = build(:api_token, organization: organization, token_digest: token.token_digest)
        expect(dup).not_to be_valid
      end

      it "generates a prefixed id" do
        expect(create(:api_token).prefix_id).to start_with("tok_")
      end
    end
  end
end
