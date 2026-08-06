require 'rails_helper'

module RivetCms
  RSpec.describe "Media Assets", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }

    def png_upload
      file = Tempfile.new([ "pic", ".png" ])
      file.binmode
      file.write("\x89PNG\r\n\x1a\n".b + "fake-image")
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "pic.png")
    end

    it "renders the media library" do
      organization
      get rivet_cms.media_assets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Media/Index")
    end

    it "returns the library as json for the picker" do
      create(:media_asset, organization: organization)
      get rivet_cms.media_assets_path, headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end

    it "uploads a file and returns its json" do
      organization
      expect {
        post rivet_cms.media_assets_path, params: { file: png_upload }
      }.to change(MediaAsset, :count).by(1)

      body = JSON.parse(response.body)
      expect(body["filename"]).to eq("pic.png")
      expect(body["kind"]).to eq("image")
      expect(body["url"]).to be_present
    end

    def html_upload(filename: "page.html", declared_type: "text/html")
      file = Tempfile.new([ "page", ".html" ])
      file.write("<html><script>alert(1)</script></html>")
      file.rewind
      Rack::Test::UploadedFile.new(file.path, declared_type, original_filename: filename)
    end

    it "rejects a file type outside the allowlist" do
      organization
      expect {
        post rivet_cms.media_assets_path, params: { file: html_upload }
      }.not_to change(MediaAsset, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].join).to include("not allowed")
    end

    it "rejects by sniffed type, not the client-declared one" do
      organization
      expect {
        post rivet_cms.media_assets_path, params: { file: html_upload(filename: "photo.png", declared_type: "image/png") }
      }.not_to change(MediaAsset, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "deletes a media asset" do
      asset = create(:media_asset, organization: organization)
      expect {
        delete rivet_cms.media_asset_path(asset)
      }.to change(MediaAsset, :count).by(-1)
    end

    it "refuses to delete media that content references" do
      asset = create(:media_asset, organization: organization)
      document = create(:document, organization: organization)
      field = create(:field, :image, content_type: document.content_type, organization: organization)
      revision = create(:document_revision, document: document)
      revision.content_values.create!(field: field, media_asset: asset)

      expect {
        delete rivet_cms.media_asset_path(asset)
      }.not_to change(MediaAsset, :count)
      expect(flash[:alert]).to include("in use")
    end

    it "refuses to delete media embedded in rich text" do
      asset = create(:media_asset, organization: organization)
      document = create(:document, organization: organization)
      field = create(:field, field_type: :rich_text, content_type: document.content_type, organization: organization)
      revision = create(:document_revision, document: document)
      revision.content_values.create!(field: field, text_value: %(<p><img src="#{asset.url}"></p>))

      expect {
        delete rivet_cms.media_asset_path(asset)
      }.not_to change(MediaAsset, :count)
      expect(flash[:alert]).to include("embedded")
    end

    it "does not list other organizations' media" do
      mine = create(:media_asset, organization: organization)
      other = create(:media_asset)

      get rivet_cms.media_assets_path, headers: { "Accept" => "application/json" }
      ids = JSON.parse(response.body).map { |a| a["id"] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it "cannot delete another organization's media" do
      organization
      other = create(:media_asset)

      delete rivet_cms.media_asset_path(other)
      expect(response).to have_http_status(:not_found)
      expect(MediaAsset.exists?(other.id)).to be true
    end

    it "identifies the real content type instead of trusting the client" do
      organization
      file = Tempfile.new([ "fake", ".png" ])
      file.write("%PDF-1.4\nfake pdf body")
      file.rewind
      upload = Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "fake.png")

      post rivet_cms.media_assets_path, params: { file: upload }
      body = JSON.parse(response.body)
      expect(body["content_type"]).to eq("application/pdf")
      expect(body["kind"]).to eq("file")
    end

    it "rejects a request without a file" do
      organization
      post rivet_cms.media_assets_path
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an upload over the configured size limit" do
      organization
      original = RivetCms.max_upload_size
      RivetCms.max_upload_size = 1

      post rivet_cms.media_assets_path, params: { file: png_upload }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].join).to include("too large")
    ensure
      RivetCms.max_upload_size = original
    end
  end
end
