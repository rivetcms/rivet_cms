require 'rails_helper'

module RivetCms
  RSpec.describe Document, type: :model do
    subject { build(:document) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires a slug" do
        subject.slug = nil
        expect(subject).not_to be_valid
      end

      it "requires unique slug within content_type" do
        ct = create(:content_type)
        create(:document, slug: "about", content_type: ct, organization: ct.organization)
        dup = build(:document, slug: "about", content_type: ct, organization: ct.organization)
        expect(dup).not_to be_valid
        expect(dup.errors[:slug]).to include("has already been taken")
      end

      it "rejects slugs that are not lowercase alphanumeric with hyphens" do
        [ "fdsaf ^&", "Hello", "spaced out", "trailing-", "-leading", "under_score" ].each do |bad|
          subject.slug = bad
          expect(subject).not_to be_valid, "expected #{bad.inspect} to be invalid"
          expect(subject.errors[:slug]).to include("must be lowercase alphanumeric with hyphens")
        end
      end

      it "accepts hyphenated lowercase slugs" do
        subject.slug = "hello-world-2"
        expect(subject).to be_valid
      end

      it "does not block entries whose slug predates the format rule" do
        doc = create(:document)
        doc.update_column(:slug, "legacy slug ^&")
        expect(doc.reload).to be_valid
      end

      it "allows the same slug in different content_types" do
        ct1 = create(:content_type)
        ct2 = create(:content_type)
        create(:document, slug: "about", content_type: ct1, organization: ct1.organization)
        doc = build(:document, slug: "about", content_type: ct2, organization: ct2.organization)
        expect(doc).to be_valid
      end
    end

    describe "single-type enforcement" do
      it "allows only one document for a single-type content type" do
        ct = create(:content_type, :single)
        create(:document, content_type: ct, organization: ct.organization)
        second = build(:document, content_type: ct, organization: ct.organization)
        expect(second).not_to be_valid
      end

      it "allows many documents for a collection content type" do
        ct = create(:content_type, :collection)
        create(:document, content_type: ct, organization: ct.organization)
        second = build(:document, content_type: ct, organization: ct.organization)
        expect(second).to be_valid
      end
    end

    describe "tenant integrity" do
      it "rejects a content_type from a different organization" do
        doc = build(:document)
        doc.content_type = create(:content_type)
        expect(doc).not_to be_valid
        expect(doc.errors[:content_type]).to be_present
      end
    end

    describe "prefix_id" do
      it "generates a prefixed id" do
        expect(create(:document).prefix_id).to start_with("doc_")
      end
    end
  end
end
