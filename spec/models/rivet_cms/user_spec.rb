require 'rails_helper'

module RivetCms
  RSpec.describe User, type: :model do
    subject { build(:user) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires name" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end

      it "requires email_address" do
        subject.email_address = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to include("can't be blank")
      end

      it "requires valid email format" do
        subject.email_address = "invalid"
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to include("is invalid")
      end

      it "requires unique email_address" do
        create(:user, email_address: "taken@example.com")
        subject.email_address = "taken@example.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:email_address]).to include("has already been taken")
      end

      it "requires password of minimum 8 characters" do
        subject.password = "short"
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "allows blank password on update" do
        user = create(:user)
        user.name = "Updated Name"
        expect(user).to be_valid
      end
    end

    describe "authentication" do
      it "authenticates with correct password" do
        user = create(:user, password: "password123")
        expect(user.authenticate("password123")).to eq(user)
      end

      it "does not authenticate with incorrect password" do
        user = create(:user, password: "password123")
        expect(user.authenticate("wrongpassword")).to be false
      end
    end

    describe "roles" do
      it "defaults to member role" do
        user = create(:user)
        expect(user.member?).to be true
      end

      it "can be admin" do
        user = create(:user, :admin)
        expect(user.admin?).to be true
      end

      it "can be owner" do
        user = create(:user, :owner)
        expect(user.owner?).to be true
      end
    end

    describe "scopes" do
      describe ".active" do
        it "returns users without deleted_at" do
          active_user = create(:user)
          deleted_user = create(:user)
          deleted_user.update!(deleted_at: Time.current)
          expect(User.active).to contain_exactly(active_user)
        end
      end

      describe ".deleted" do
        it "returns users with deleted_at" do
          create(:user)
          deleted_user = create(:user, :deleted)
          expect(User.deleted).to contain_exactly(deleted_user)
        end
      end

      describe ".pending_invitation" do
        it "returns users with invited_at but no accepted_at" do
          create(:user)
          invited_user = create(:user, :invited)
          create(:user, :accepted)
          expect(User.pending_invitation).to contain_exactly(invited_user)
        end
      end
    end

    describe "#soft_delete" do
      it "sets deleted_at and deleted_by" do
        user = create(:user)
        admin = create(:user, :admin)

        freeze_time do
          user.soft_delete(by: admin)
          expect(user.deleted_at).to eq(Time.current)
          expect(user.deleted_by).to eq(admin)
        end
      end
    end

    describe "#deleted?" do
      it "returns true when deleted_at is present" do
        user = create(:user, :deleted)
        expect(user.deleted?).to be true
      end

      it "returns false when deleted_at is nil" do
        user = create(:user)
        expect(user.deleted?).to be false
      end
    end

    describe "#pending_invitation?" do
      it "returns true when invited but not accepted" do
        user = create(:user, :invited)
        expect(user.pending_invitation?).to be true
      end

      it "returns false when accepted" do
        user = create(:user, :accepted)
        expect(user.pending_invitation?).to be false
      end

      it "returns false when not invited" do
        user = create(:user)
        expect(user.pending_invitation?).to be false
      end
    end

    describe "factory" do
      it "creates a valid user" do
        expect(create(:user)).to be_persisted
      end

      it "creates admin with trait" do
        expect(create(:user, :admin).admin?).to be true
      end

      it "creates owner with trait" do
        expect(create(:user, :owner).owner?).to be true
      end

      it "creates invited user with trait" do
        user = create(:user, :invited)
        expect(user.invited_at).to be_present
        expect(user.invited_by).to be_present
      end

      it "creates deleted user with trait" do
        user = create(:user, :deleted)
        expect(user.deleted_at).to be_present
        expect(user.deleted_by).to be_present
      end
    end
  end
end
