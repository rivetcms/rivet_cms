module RivetCms
  # Fans a lifecycle event out to the host-configured webhook endpoints.
  # RivetCms.webhooks is an array of { url:, events: } hashes; events is
  # optional and defaults to everything.
  module Webhooks
    EVENT_NAMES = { publish: "entry.published" }.freeze

    def self.deliver(event, revision)
      endpoints_for(event).each do |endpoint|
        url = endpoint[:url] || endpoint["url"]
        next if url.blank?

        WebhookDeliveryJob.perform_later(url, payload(event, revision))
      end
    end

    def self.endpoints_for(event)
      name = EVENT_NAMES.fetch(event, event.to_s)
      Array(RivetCms.webhooks).select do |endpoint|
        events = endpoint[:events] || endpoint["events"]
        events.nil? || events.map(&:to_s).include?(name)
      end
    end

    def self.payload(event, revision)
      document = revision.document
      {
        event: EVENT_NAMES.fetch(event),
        document_id: document.prefix_id,
        slug: document.slug,
        # with_discarded: publishing into a removed type is reachable from host
        # code, and the payload should still say which type it was.
        content_type: ContentType.with_discarded.where(id: document.content_type_id).pick(:slug),
        organization: document.organization.subdomain,
        locale: revision.locale,
        published_at: revision.published_at&.iso8601,
        author: revision.author_name
      }
    end

    # Fails fast at boot so a malformed entry cannot silently disable
    # delivery (publish-path errors are swallowed by the hook seam).
    def self.validate_config!
      Array(RivetCms.webhooks).each do |endpoint|
        raise ArgumentError, "RivetCms.webhooks entries must be hashes, got #{endpoint.class}" unless endpoint.is_a?(Hash)

        url = endpoint[:url] || endpoint["url"]
        uri = URI.parse(url.to_s) rescue nil
        unless uri.is_a?(URI::HTTP) # covers HTTPS (subclass)
          raise ArgumentError, "RivetCms.webhooks url must be http(s), got #{url.inspect}"
        end

        events = endpoint[:events] || endpoint["events"]
        next if events.nil?
        unless events.is_a?(Array) && (events.map(&:to_s) - EVENT_NAMES.values).empty?
          raise ArgumentError, "RivetCms.webhooks events must be an array from #{EVENT_NAMES.values.inspect}, got #{events.inspect}"
        end
      end
    end
  end
end
