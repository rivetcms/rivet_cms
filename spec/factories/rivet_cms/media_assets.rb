FactoryBot.define do
  factory :media_asset, class: "RivetCms::MediaAsset" do
    organization

    after(:build) do |asset|
      png = "\x89PNG\r\n\x1a\n".b + "fake-image-data"
      asset.file.attach(io: StringIO.new(png), filename: "image.png", content_type: "image/png")
    end
  end
end
