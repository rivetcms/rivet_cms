require 'rails_helper'

module RivetCms
  RSpec.describe ContentType, type: :model do
    subject { build(:content_type) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires name" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end

      it "requires slug" do
        # Slug is auto-generated from name, so both must be nil to trigger validation
        subject.name = nil
        subject.slug = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:slug]).to include("can't be blank")
      end

      it "requires unique slug within organization" do
        org = create(:organization)
        create(:content_type, slug: "taken", organization: org)
        subject.slug = "taken"
        subject.organization = org
        expect(subject).not_to be_valid
        expect(subject.errors[:slug]).to include("has already been taken")
      end

      it "allows same slug in different organizations" do
        org1 = create(:organization)
        org2 = create(:organization)
        create(:content_type, slug: "blog", organization: org1)
        content_type = build(:content_type, slug: "blog", organization: org2)
        expect(content_type).to be_valid
      end

      it "validates single inclusion" do
        subject.single = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:single]).to include("is not included in the list")
      end
    end

    describe "scopes" do
      let(:org) { create(:organization) }

      describe ".singles" do
        it "returns only single content types" do
          single = create(:content_type, :single, organization: org)
          create(:content_type, :collection, organization: org)
          expect(ContentType.singles).to contain_exactly(single)
        end
      end

      describe ".collections" do
        it "returns only collection content types" do
          create(:content_type, :single, organization: org)
          collection = create(:content_type, :collection, organization: org)
          expect(ContentType.collections).to contain_exactly(collection)
        end
      end
    end

    describe "#collection?" do
      it "returns true when single is false" do
        content_type = build(:content_type, single: false)
        expect(content_type.collection?).to be true
      end

      it "returns false when single is true" do
        content_type = build(:content_type, single: true)
        expect(content_type.collection?).to be false
      end
    end

    describe "prefix_id" do
      it "generates prefixed id" do
        content_type = create(:content_type)
        expect(content_type.prefix_id).to start_with("ctype_")
      end
    end

    describe "factory" do
      it "creates a valid content_type" do
        expect(create(:content_type)).to be_persisted
      end

      it "creates single content type with trait" do
        expect(create(:content_type, :single).single?).to be true
      end

      it "creates collection content type with trait" do
        expect(create(:content_type, :collection).single?).to be false
      end
    end
  end
end
