require 'rails_helper'

module RivetCms
  RSpec.describe Component, type: :model do
    subject { build(:component) }

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
        category = create(:category, organization: org)
        create(:component, slug: "taken", organization: org, category: category)
        subject.slug = "taken"
        subject.organization = org
        subject.category = category
        expect(subject).not_to be_valid
        expect(subject.errors[:slug]).to include("has already been taken")
      end

      it "allows same slug in different organizations" do
        org1 = create(:organization)
        org2 = create(:organization)
        cat1 = create(:category, organization: org1)
        cat2 = create(:category, organization: org2)
        create(:component, slug: "hero", organization: org1, category: cat1)
        component = build(:component, slug: "hero", organization: org2, category: cat2)
        expect(component).to be_valid
      end

      it "validates repeatable inclusion" do
        subject.repeatable = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:repeatable]).to include("is not included in the list")
      end

      it "requires category" do
        subject.category = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:category]).to include("must exist")
      end
    end

    describe "associations" do
      it "belongs to category" do
        category = create(:category)
        component = create(:component, category: category, organization: category.organization)
        expect(component.category).to eq(category)
      end
    end

    describe "scopes" do
      let(:org) { create(:organization) }
      let(:category) { create(:category, organization: org) }

      describe ".repeatable" do
        it "returns only repeatable components" do
          repeatable = create(:component, :repeatable, organization: org, category: category)
          create(:component, :single, organization: org, category: category)
          expect(Component.repeatable).to contain_exactly(repeatable)
        end
      end

      describe ".single" do
        it "returns only single components" do
          create(:component, :repeatable, organization: org, category: category)
          single = create(:component, :single, organization: org, category: category)
          expect(Component.single).to contain_exactly(single)
        end
      end
    end

    describe "prefix_id" do
      it "generates prefixed id" do
        component = create(:component)
        expect(component.prefix_id).to start_with("comp_")
      end
    end

    describe "factory" do
      it "creates a valid component" do
        expect(create(:component)).to be_persisted
      end

      it "creates repeatable component with trait" do
        expect(create(:component, :repeatable).repeatable?).to be true
      end

      it "creates single component with trait" do
        expect(create(:component, :single).repeatable?).to be false
      end
    end
  end
end
