require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  describe "GET /" do
    it "returns http success" do
      get rivet_cms.root_path
      expect(response).to have_http_status(:success)
    end
  end
end
