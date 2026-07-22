require 'rails_helper'

module RivetCms
  RSpec.describe Organization, type: :model do
    subject { build(:organization) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires name" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end

      it "requires domain" do
        subject.domain = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:domain]).to include("can't be blank")
      end

      it "requires unique domain" do
        create(:organization, domain: "taken.example.com")
        subject.domain = "taken.example.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:domain]).to include("has already been taken")
      end

      it "allows blank subdomain" do
        subject.subdomain = nil
        expect(subject).to be_valid
      end

      it "requires unique subdomain when present" do
        create(:organization, subdomain: "taken")
        subject.subdomain = "taken"
        expect(subject).not_to be_valid
        expect(subject.errors[:subdomain]).to include("has already been taken")
      end
    end

    describe "associations" do
      it "has many users" do
        org = create(:organization)
        user = create(:user, organization: org)
        expect(org.users).to include(user)
      end

      it "has many content_types" do
        org = create(:organization)
        content_type = create(:content_type, organization: org)
        expect(org.content_types).to include(content_type)
      end

      it "has many categories" do
        org = create(:organization)
        category = create(:category, organization: org)
        expect(org.categories).to include(category)
      end

      it "has many components" do
        org = create(:organization)
        category = create(:category, organization: org)
        component = create(:component, organization: org, category: category)
        expect(org.components).to include(component)
      end

      it "destroys associated users when destroyed" do
        org = create(:organization)
        user = create(:user, organization: org)
        expect { org.destroy }.to change { User.count }.by(-1)
      end

      it "destroys associated content_types when destroyed" do
        org = create(:organization)
        create(:content_type, organization: org)
        expect { org.destroy }.to change { ContentType.count }.by(-1)
      end

      it "destroys associated categories when destroyed" do
        org = create(:organization)
        create(:category, organization: org)
        expect { org.destroy }.to change { Category.count }.by(-1)
      end

      it "destroys associated media assets when destroyed" do
        org = create(:organization)
        create(:media_asset, organization: org)
        expect { org.destroy }.to change { MediaAsset.count }.by(-1)
      end
    end

    describe "factory" do
      it "creates a valid organization" do
        expect(create(:organization)).to be_persisted
      end

      it "creates a default organization with trait" do
        org = create(:organization, :default)
        expect(org.default).to be true
      end

      it "creates organization with subdomain using trait" do
        org = create(:organization, :with_subdomain)
        expect(org.subdomain).to be_present
      end
    end
  end
end
