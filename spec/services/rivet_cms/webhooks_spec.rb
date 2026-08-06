require 'rails_helper'

module RivetCms
  RSpec.describe Webhooks do
    include ActiveJob::TestHelper

    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    def published_revision
      document = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft, author_name: "Nathan")
      document.update!(draft_revision: draft)
      draft.publish!
    end

    around do |example|
      original = RivetCms.webhooks
      example.run
    ensure
      RivetCms.webhooks = original
    end

    it "publishing enqueues a delivery per matching endpoint via the hook seam" do
      RivetCms.webhooks = [
        { url: "https://example.com/hooks", events: %w[entry.published] },
        { url: "https://example.com/other", events: %w[entry.deleted] }
      ]

      expect {
        published_revision
      }.to have_enqueued_job(WebhookDeliveryJob).exactly(:once).with { |url, payload|
        expect(url).to eq("https://example.com/hooks")
        expect(payload[:event]).to eq("entry.published")
        expect(payload[:slug]).to eq("hello")
        expect(payload[:content_type]).to eq("articles")
        expect(payload[:organization]).to eq(organization.subdomain)
        expect(payload[:author]).to eq("Nathan")
      }
    end

    it "endpoints without an events list receive everything" do
      RivetCms.webhooks = [ { "url" => "https://example.com/all" } ]

      expect { published_revision }.to have_enqueued_job(WebhookDeliveryJob)
    end

    it "no webhooks configured enqueues nothing" do
      RivetCms.webhooks = []

      expect { published_revision }.not_to have_enqueued_job(WebhookDeliveryJob)
    end

    def stub_http(response)
      http = instance_double(Net::HTTP)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:write_timeout=)
      allow(http).to receive(:request).and_return(response)
      http
    end

    it "delivery posts JSON over TLS to the parsed host and port" do
      http = stub_http(Net::HTTPSuccess.new("1.1", "200", "OK"))
      expect(Net::HTTP).to receive(:new).with("example.com", 8443).and_return(http)
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:request) do |request|
        expect(request.path).to eq("/hooks?token=abc")
        expect(request["Content-Type"]).to eq("application/json")
        expect(JSON.parse(request.body)["event"]).to eq("entry.published")
        Net::HTTPSuccess.new("1.1", "200", "OK")
      end

      WebhookDeliveryJob.perform_now("https://example.com:8443/hooks?token=abc", { event: "entry.published" })
    end

    it "delivery unwraps IPv6 literal hosts" do
      http = stub_http(Net::HTTPSuccess.new("1.1", "200", "OK"))
      expect(Net::HTTP).to receive(:new).with("::1", 9292).and_return(http)
      allow(http).to receive(:use_ssl=)

      WebhookDeliveryJob.perform_now("http://[::1]:9292/hook", { event: "entry.published" })
    end

    it "delivery raises on a non-2xx response so adapter retries apply" do
      http = stub_http(Net::HTTPServiceUnavailable.new("1.1", "503", "Service Unavailable"))
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)

      expect {
        WebhookDeliveryJob.perform_now("https://example.com/hooks?token=secret", { event: "entry.published" })
      }.to raise_error(WebhookDeliveryJob::DeliveryError) { |error|
        expect(error.message).to include("example.com")
        expect(error.message).not_to include("secret")
      }
    end

    describe "post-commit deferral" do
      # Transactional fixtures wrap examples in a non-joinable transaction
      # that after_all_transactions_commit ignores, so the deferral machinery
      # only engages outside them.
      self.use_transactional_tests = false

      it "defers hooks past an outer transaction and drops them on rollback" do
        RivetCms.webhooks = [ { url: "https://example.com/hooks" } ]
        type = create(:content_type, slug: "tx-articles", organization: organization)
        document = create(:document, slug: "tx-hello", content_type: type, organization: organization)
        draft = create(:document_revision, document: document, state: :draft, author_name: "Nathan")
        document.update!(draft_revision: draft)

        ActiveRecord::Base.transaction do
          draft.publish!
          raise ActiveRecord::Rollback
        end
        expect(enqueued_jobs).to be_empty

        enqueued_inside = nil
        ActiveRecord::Base.transaction do
          draft.publish!
          enqueued_inside = enqueued_jobs.size
        end
        expect(enqueued_inside).to eq(0)
        expect(enqueued_jobs.size).to eq(1)
      ensure
        clear_enqueued_jobs
        document&.destroy
        type&.destroy
      end
    end

    it "validates webhook config shape at boot" do
      RivetCms.webhooks = [ "https://example.com/hook" ]
      expect { Webhooks.validate_config! }.to raise_error(ArgumentError, /must be hashes/)

      RivetCms.webhooks = [ { url: "not a url" } ]
      expect { Webhooks.validate_config! }.to raise_error(ArgumentError, /must be http/)

      RivetCms.webhooks = [ { url: "https://example.com/hook", events: "entry.published" } ]
      expect { Webhooks.validate_config! }.to raise_error(ArgumentError, /events must be an array/)

      RivetCms.webhooks = [ { url: "https://example.com/hook", events: %w[entry.publish] } ]
      expect { Webhooks.validate_config! }.to raise_error(ArgumentError, /events must be an array from/)

      RivetCms.webhooks = [ { url: "https://example.com/hook", events: %w[entry.published] } ]
      expect { Webhooks.validate_config! }.not_to raise_error
    end
  end
end
