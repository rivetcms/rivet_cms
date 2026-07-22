require 'rails_helper'

module RivetCms
  RSpec.describe MediaAsset, type: :model do
    describe "#url" do
      it "is a relative path by default" do
        expect(create(:media_asset).url).to start_with("/")
      end

      it "is absolute when media_host is configured" do
        RivetCms.media_host = "https://cms.example.com"
        expect(create(:media_asset).url).to start_with("https://cms.example.com/")
      ensure
        RivetCms.media_host = nil
      end
    end

    describe "identification" do
      it "caches metadata from the identified blob" do
        asset = create(:media_asset)
        expect(asset.content_type).to eq("image/png")
        expect(asset.kind).to eq("image")
        expect(asset.byte_size).to be > 0
      end
    end
  end
end
