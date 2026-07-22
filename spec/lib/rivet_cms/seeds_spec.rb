require "rails_helper"
require "rivet_cms/seeds"

module RivetCms
  RSpec.describe Seeds do
    let(:organization) { create(:organization) }

    def field_for(content_type, key)
      content_type.fields.kept.find_by(key: key)
    end

    describe ".available" do
      it "lists the bundled templates" do
        expect(described_class.available).to include("blog", "pages", "site_settings", "events")
      end
    end

    describe ".load!" do
      it "creates a content type with typed fields" do
        described_class.load!(organization: organization, only: %w[events])

        event = organization.content_types.find_by(slug: "events")
        expect(event).to be_present
        expect(field_for(event, "starts_at").field_type).to eq("datetime")
        expect(field_for(event, "starts_at")).to be_required
        expect(field_for(event, "title")).to be_required
      end

      it "resolves a reference field to its target content type" do
        described_class.load!(organization: organization, only: %w[blog])

        posts = organization.content_types.find_by(slug: "posts")
        authors = organization.content_types.find_by(slug: "authors")
        author_field = field_for(posts, "author")

        expect(author_field.field_type).to eq("reference")
        expect(author_field.config["content_type_id"]).to eq(authors.id)
        expect(author_field.max_items).to eq(1)
      end

      it "resolves a component field to its component" do
        described_class.load!(organization: organization, only: %w[blog])

        posts = organization.content_types.find_by(slug: "posts")
        seo = organization.components.find_by(slug: "seo")
        seo_field = field_for(posts, "seo")

        expect(seo_field.field_type).to eq("component")
        expect(seo_field.config["component_id"]).to eq(seo.id)
        expect(seo.fields.kept.pluck(:key)).to include("meta_title", "og_image")
      end

      it "pairs adjacent half-width fields onto the same row" do
        described_class.load!(organization: organization, only: %w[blog])

        authors = organization.content_types.find_by(slug: "authors")
        name = field_for(authors, "name")
        email = field_for(authors, "email")

        expect(name.width).to eq("half")
        expect(name.row).to eq(email.row)
        expect([ name.position, email.position ]).to contain_exactly(0, 1)
      end

      it "creates a single-type content type" do
        described_class.load!(organization: organization, only: %w[site_settings])

        settings = organization.content_types.find_by(slug: "site-settings")
        expect(settings.single).to be(true)
      end

      it "is idempotent" do
        described_class.load!(organization: organization, only: %w[blog])
        content_types = organization.content_types.count
        fields = RivetCms::Field.where(organization: organization).count

        described_class.load!(organization: organization, only: %w[blog])

        expect(organization.content_types.count).to eq(content_types)
        expect(RivetCms::Field.where(organization: organization).count).to eq(fields)
      end
    end
  end
end
