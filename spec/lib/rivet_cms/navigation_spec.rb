require 'rails_helper'

module RivetCms
  RSpec.describe Navigation do
    it "registers the core sidebar out of the box" do
      keys = described_class.items.map(&:key)
      expect(keys).to eq(%i[dashboard content content_types components media api api_tokens])
    end

    it "core gates mirror the index actions they link to" do
      gates = described_class.items.to_h { |item| [ item.key, item.requires ] }
      expect(gates).to include(
        dashboard: nil,
        content: %i[read content],
        content_types: %i[read schema],
        components: %i[read schema],
        media: %i[read media],
        api: %i[read api],
        api_tokens: %i[read api]
      )
    end

    it "sorts registered items by position across sections" do
      described_class.register :early, label: "Early", section: "Manage", path: "/early", position: 25

      keys = described_class.items.map(&:key)
      expect(keys.index(:early)).to eq(keys.index(:content) + 1)
    end

    it "re-registering a key replaces the item instead of duplicating" do
      described_class.register :thing, label: "One", section: "Pro", path: "/one"
      described_class.register :thing, label: "Two", section: "Pro", path: "/two"

      things = described_class.items.select { |item| item.key == :thing }
      expect(things.map(&:label)).to eq([ "Two" ])
    end

    it "unregisters an item" do
      described_class.register :gone, label: "Gone", section: "Pro", path: "/gone"
      described_class.unregister(:gone)

      expect(described_class.items.map(&:key)).not_to include(:gone)
    end

    it "rejects a blank label" do
      expect {
        described_class.register :bad, label: " ", section: "Pro", path: "/x"
      }.to raise_error(ArgumentError, /label/)
    end

    it "rejects a path that is neither string nor callable" do
      expect {
        described_class.register :bad, label: "Bad", section: "Pro", path: 42
      }.to raise_error(ArgumentError, /path/)
    end

    it "rejects a malformed requires" do
      expect {
        described_class.register :bad, label: "Bad", section: "Pro", path: "/x", requires: :read
      }.to raise_error(ArgumentError, /requires/)
    end

    it "rejects a non-integer position" do
      expect {
        described_class.register :bad, label: "Bad", section: "Pro", path: "/x", position: "10"
      }.to raise_error(ArgumentError, /position/)
    end

    it "rejects a Duration position, which lies about being an Integer" do
      expect {
        described_class.register :bad, label: "Bad", section: "Pro", path: "/x", position: 5.days
      }.to raise_error(ArgumentError, /position/)
    end

    it "snapshot and restore give the registry back exactly as found" do
      before = described_class.items.map(&:key)
      snapshot = described_class.snapshot
      described_class.register :extra, label: "Extra", section: "Pro", path: "/extra"
      described_class.unregister(:dashboard)

      described_class.restore(snapshot)

      expect(described_class.items.map(&:key)).to eq(before)
    end

    it "restore(nil) leaves the registry alone" do
      before = described_class.items.map(&:key)
      described_class.restore(nil)
      expect(described_class.items.map(&:key)).to eq(before)
    end
  end
end
