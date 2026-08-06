require 'rails_helper'

module RivetCms
  RSpec.describe Hooks do
    around do |example|
      # Preserve boot-time subscribers (the webhook dispatcher) across resets
      original = Hooks.instance_variable_get(:@registry)
      Hooks.reset!
      example.run
    ensure
      Hooks.instance_variable_set(:@registry, original)
    end

    it "runs subscribers for an event" do
      seen = []
      Hooks.on(:publish) { |arg| seen << arg }

      Hooks.run(:publish, :revision)

      expect(seen).to eq([ :revision ])
    end

    it "rejects unknown events" do
      expect { Hooks.on(:bogus) { } }.to raise_error(ArgumentError, /unknown event/)
    end

    it "extensions can register new events and subscribe to them" do
      seen = []
      Hooks.register_event(:unpublish)
      Hooks.on(:unpublish) { |arg| seen << arg }

      Hooks.run(:unpublish, :doc)

      expect(seen).to eq([ :doc ])
    end

    it "running an event with no subscribers is a no-op" do
      expect { Hooks.run(:publish) }.not_to raise_error
    end

    it "swallows and logs a failing subscriber without breaking others" do
      seen = []
      Hooks.on(:publish) { raise "boom" }
      Hooks.on(:publish) { seen << :ran }

      expect { Hooks.run(:publish) }.not_to raise_error
      expect(seen).to eq([ :ran ])
    end

    it "replaces the handler when re-registered with the same key" do
      seen = []
      Hooks.on(:publish, key: :sitemap) { seen << :first }
      Hooks.on(:publish, key: :sitemap) { seen << :second }

      Hooks.run(:publish)

      expect(seen).to eq([ :second ])
    end

    it "re-registering the same handler object does not duplicate it" do
      seen = []
      handler = -> { seen << :ran }
      Hooks.on(:publish, handler)
      Hooks.on(:publish, handler)

      Hooks.run(:publish)

      expect(seen).to eq([ :ran ])
    end

    it "accepts a callable in place of a block" do
      seen = []
      Hooks.on(:publish, ->(arg) { seen << arg })

      Hooks.run(:publish, 1)

      expect(seen).to eq([ 1 ])
    end
  end
end
