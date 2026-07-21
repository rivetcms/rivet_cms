require 'rails_helper'

module RivetCms
  RSpec.describe Category, type: :model do
    subject { build(:category) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires name" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end

      it "requires slug" do
        subject.slug = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:slug]).to include("can't be blank")
      end

      it "requires unique slug within organization" do
        org = create(:organization)
        create(:category, slug: "taken", organization: org)
        subject.slug = "taken"
        subject.organization = org
        expect(subject).not_to be_valid
        expect(subject.errors[:slug]).to include("has already been taken")
      end

      it "allows same slug in different organizations" do
        org1 = create(:organization)
        org2 = create(:organization)
        create(:category, slug: "media", organization: org1)
        category = build(:category, slug: "media", organization: org2)
        expect(category).to be_valid
      end

      it "validates system inclusion" do
        subject.system = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:system]).to include("is not included in the list")
      end
    end

    describe "associations" do
      it "has many components" do
        category = create(:category)
        component = create(:component, category: category, organization: category.organization)
        expect(category.components).to include(component)
      end

      it "prevents destruction when components exist" do
        category = create(:category)
        create(:component, category: category, organization: category.organization)
        expect { category.destroy }.not_to change { Category.count }
        expect(category.errors[:base]).to include("Cannot delete record because dependent components exist")
      end

      it "allows destruction when no components exist" do
        category = create(:category)
        expect { category.destroy }.to change { Category.count }.by(-1)
      end
    end

    describe "scopes" do
      let(:org) { create(:organization) }

      describe ".system_categories" do
        it "returns only system categories" do
          system_cat = create(:category, :system, organization: org)
          create(:category, organization: org)
          expect(Category.system_categories).to contain_exactly(system_cat)
        end
      end

      describe ".custom_categories" do
        it "returns only custom categories" do
          create(:category, :system, organization: org)
          custom_cat = create(:category, organization: org)
          expect(Category.custom_categories).to contain_exactly(custom_cat)
        end
      end

      describe ".ordered" do
        it "orders by position" do
          cat3 = create(:category, position: 3, organization: org)
          cat1 = create(:category, position: 1, organization: org)
          cat2 = create(:category, position: 2, organization: org)
          expect(Category.ordered).to eq([ cat1, cat2, cat3 ])
        end
      end
    end

    describe "#destroyable?" do
      it "returns true when not system and no components" do
        category = create(:category, system: false)
        expect(category.destroyable?).to be true
      end

      it "returns false when system" do
        category = create(:category, :system)
        expect(category.destroyable?).to be false
      end

      it "returns false when has components" do
        category = create(:category)
        create(:component, category: category, organization: category.organization)
        expect(category.destroyable?).to be false
      end
    end

    describe "prefix_id" do
      it "generates prefixed id" do
        category = create(:category)
        expect(category.prefix_id).to start_with("cat_")
      end
    end

    describe "factory" do
      it "creates a valid category" do
        expect(create(:category)).to be_persisted
      end

      it "creates system category with trait" do
        expect(create(:category, :system).system?).to be true
      end
    end
  end
end
