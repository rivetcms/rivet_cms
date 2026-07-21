require 'rails_helper'

module RivetCms
  RSpec.describe Field, type: :model do
    subject { build(:field) }

    describe "validations" do
      it { is_expected.to be_valid }

      it "requires name" do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end

      it "requires field_type" do
        subject.field_type = nil
        expect(subject).not_to be_valid
      end

      it "requires unique name within content_type" do
        content_type = create(:content_type)
        create(:field, name: "title", content_type: content_type, organization: content_type.organization)
        field = build(:field, name: "title", content_type: content_type, organization: content_type.organization)
        expect(field).not_to be_valid
        expect(field.errors[:name]).to include("has already been taken")
      end

      it "allows same name in different content_types" do
        ct1 = create(:content_type)
        ct2 = create(:content_type)
        create(:field, name: "title", content_type: ct1, organization: ct1.organization)
        field = build(:field, name: "title", content_type: ct2, organization: ct2.organization)
        expect(field).to be_valid
      end

      it "requires either content_type or component" do
        subject.content_type = nil
        subject.component = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include("Field must belong to either content_type or component")
      end

      it "cannot belong to both content_type and component" do
        subject.component = create(:component, organization: subject.organization)
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include("Field cannot belong to both content_type and component")
      end
    end

    describe "field types" do
      Field.field_types.keys.each do |field_type|
        it "supports #{field_type} type" do
          field = build(:field, field_type: field_type)
          expect(field.field_type).to eq(field_type)
          expect(field.send("#{field_type}?")).to be true
        end
      end
    end

    describe "#attachment?" do
      it "returns true for image, video, file types" do
        expect(build(:field, :image).attachment?).to be true
        expect(build(:field, :video).attachment?).to be true
        expect(build(:field, :file).attachment?).to be true
      end

      it "returns false for other types" do
        expect(build(:field, :string).attachment?).to be false
        expect(build(:field, :text).attachment?).to be false
        expect(build(:field, :boolean).attachment?).to be false
      end
    end

    describe "#field_type_label" do
      it "returns human-readable labels" do
        expect(build(:field, :string).field_type_label).to eq("Short text")
        expect(build(:field, :rich_text).field_type_label).to eq("Rich text")
        expect(build(:field, :boolean).field_type_label).to eq("True/False")
      end
    end

    describe "soft delete" do
      it "can be discarded" do
        field = create(:field)
        field.discard
        expect(field.discarded?).to be true
        expect(Field.count).to eq(0)
        expect(Field.with_discarded.count).to eq(1)
      end

      it "can be undiscarded" do
        field = create(:field, :discarded)
        field.undiscard
        expect(field.kept?).to be true
      end

      it "allows reusing name after soft delete" do
        content_type = create(:content_type)
        field = create(:field, name: "title", content_type: content_type, organization: content_type.organization)
        field.discard

        new_field = build(:field, name: "title", content_type: content_type, organization: content_type.organization)
        expect(new_field).to be_valid
      end
    end

    describe "position" do
      it "auto-assigns position on create" do
        content_type = create(:content_type)
        field1 = create(:field, content_type: content_type, organization: content_type.organization)
        field2 = create(:field, content_type: content_type, organization: content_type.organization)
        expect(field1.position).to eq(1)
        expect(field2.position).to eq(2)
      end
    end

    describe ".reorder!" do
      it "updates positions based on ordered ids" do
        content_type = create(:content_type)
        org = content_type.organization
        field1 = create(:field, content_type: content_type, organization: org)
        field2 = create(:field, content_type: content_type, organization: org)
        field3 = create(:field, content_type: content_type, organization: org)

        Field.reorder!([ field3.id, field1.id, field2.id ])

        expect(field3.reload.position).to eq(0)
        expect(field1.reload.position).to eq(1)
        expect(field2.reload.position).to eq(2)
      end
    end
  end
end
