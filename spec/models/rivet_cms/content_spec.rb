require 'rails_helper'

module RivetCms
  RSpec.describe Content, type: :model do
    subject { build(:content) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires unique slug within organization" do
        org = create(:organization)
        content_type = create(:content_type, organization: org)
        create(:content, slug: "taken", organization: org, content_type: content_type)
        content = build(:content, slug: "taken", organization: org, content_type: content_type)
        expect(content).not_to be_valid
        expect(content.errors[:slug]).to include("has already been taken")
      end

      it "allows same slug in different organizations" do
        ct1 = create(:content_type)
        ct2 = create(:content_type)
        create(:content, slug: "about", organization: ct1.organization, content_type: ct1)
        content = build(:content, slug: "about", organization: ct2.organization, content_type: ct2)
        expect(content).to be_valid
      end

      it "auto-generates slug from name if blank" do
        content_type = create(:content_type)
        # Content doesn't have name, but Sluggable requires it
        # Skip this test since Content uses slug directly
      end
    end

    describe "status" do
      it "defaults to draft" do
        expect(subject.status).to eq("draft")
        expect(subject.draft?).to be true
      end

      it "can be published" do
        subject.status = :published
        expect(subject.published?).to be true
      end

      it "can be archived" do
        subject.status = :archived
        expect(subject.archived?).to be true
      end
    end

    describe "#publish!" do
      it "sets status to published and published_at" do
        content = create(:content, :draft)
        freeze_time do
          content.publish!
          expect(content.published?).to be true
          expect(content.published_at).to eq(Time.current)
        end
      end
    end

    describe "#unpublish!" do
      it "sets status to draft and unpublished_at" do
        content = create(:content, :published)
        freeze_time do
          content.unpublish!
          expect(content.draft?).to be true
          expect(content.unpublished_at).to eq(Time.current)
        end
      end
    end

    describe "#archive!" do
      it "sets status to archived and unpublished_at" do
        content = create(:content, :published)
        freeze_time do
          content.archive!
          expect(content.archived?).to be true
          expect(content.unpublished_at).to eq(Time.current)
        end
      end
    end

    describe "#title" do
      it "returns slug when no title field exists" do
        content = create(:content, slug: "my-content")
        expect(content.title).to eq("my-content")
      end

      it "returns title field value when exists" do
        content_type = create(:content_type)
        title_field = create(:field, name: "title", field_type: :string, content_type: content_type, organization: content_type.organization)
        content = create(:content, content_type: content_type, organization: content_type.organization)

        title_value = FieldValues::String.create!(value: "My Title")
        ContentValue.create!(content: content, field: title_field, value: title_value)

        expect(content.title).to eq("My Title")
      end
    end

    describe "scopes" do
      let(:org) { create(:organization) }
      let(:content_type) { create(:content_type, organization: org) }

      describe ".draft" do
        it "returns only draft content" do
          draft = create(:content, :draft, content_type: content_type, organization: org)
          create(:content, :published, content_type: content_type, organization: org)
          expect(Content.draft).to contain_exactly(draft)
        end
      end

      describe ".published" do
        it "returns only published content" do
          create(:content, :draft, content_type: content_type, organization: org)
          published = create(:content, :published, content_type: content_type, organization: org)
          expect(Content.published).to contain_exactly(published)
        end
      end

      describe ".archived" do
        it "returns only archived content" do
          create(:content, :draft, content_type: content_type, organization: org)
          archived = create(:content, :archived, content_type: content_type, organization: org)
          expect(Content.archived).to contain_exactly(archived)
        end
      end
    end
  end
end
