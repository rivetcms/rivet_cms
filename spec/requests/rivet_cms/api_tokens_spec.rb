require 'rails_helper'

module RivetCms
  RSpec.describe "API Tokens admin", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    it "creates a token and reveals the plaintext exactly once" do
      organization
      post rivet_cms.api_tokens_path, params: { name: "Site", scope: "preview" }
      follow_redirect!

      token = ApiToken.last
      expect(token.scope).to eq("preview")
      # Plaintext appears once via flash on the redirect target...
      expect(response.body).to include(token.token_last4)
      expect(response.body).not_to include(token.token_digest)

      # ...and is gone on a fresh load.
      get rivet_cms.api_tokens_path
      expect(response.body).to include(token.masked)
    end

    it "revokes a token" do
      token = create(:api_token, organization: organization)
      expect {
        delete rivet_cms.api_token_path(token)
      }.to change(ApiToken, :count).by(-1)
      expect(ApiToken.authenticate(token.token_digest)).to be_nil
    end

    it "cannot revoke another organization's token" do
      organization
      other = create(:api_token)
      delete rivet_cms.api_token_path(other)
      expect(response).to have_http_status(:not_found)
      expect(ApiToken.exists?(other.id)).to be true
    end

    it "does not list other organizations' tokens" do
      mine = create(:api_token, name: "Mine", organization: organization)
      create(:api_token, name: "Theirs")

      get rivet_cms.api_tokens_path
      expect(response.body).to include("Mine")
      expect(response.body).not_to include("Theirs")
    end
  end
end
