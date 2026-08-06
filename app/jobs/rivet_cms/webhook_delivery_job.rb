require "net/http"

module RivetCms
  # Basic CE webhook delivery: one POST, JSON body, short timeouts, no
  # signing. Any failure (connection error or non-2xx response) raises, so
  # retry behavior uniformly follows the host's queue adapter defaults.
  class WebhookDeliveryJob < ApplicationJob
    # Webhook URLs are often capability URLs (tokens in path or query):
    # keep them out of job argument logs, and log only the host on failure.
    self.log_arguments = false

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10
    WRITE_TIMEOUT = 10

    class DeliveryError < StandardError; end

    def perform(url, payload)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.write_timeout = WRITE_TIMEOUT

      request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json", "User-Agent" => "RivetCMS/#{RivetCms::VERSION}")
      request.body = payload.to_json
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise DeliveryError, "webhook to #{uri.host} responded #{response.code}"
      end
    end
  end
end
