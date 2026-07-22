require "digest"
require "securerandom"

module RivetCms
  class ApiToken < ApplicationRecord
    include OrganizationScoped

    has_prefix_id :tok

    enum :scope, { published: 0, preview: 1 }

    validates :name, presence: true
    validates :token_digest, presence: true, uniqueness: true
    validates :token_last4, presence: true

    scope :recent, -> { order(created_at: :desc) }

    # Set only on the record returned by generate!; the secret is never stored.
    attr_reader :plaintext

    def self.digest(raw)
      Digest::SHA256.hexdigest(raw.to_s)
    end

    def self.generate!(name:, scope: :published, organization: RivetCms::Current.organization, expires_at: nil)
      raw = SecureRandom.hex(32)
      token = create!(
        name: name,
        scope: scope,
        organization: organization,
        expires_at: expires_at,
        token_digest: digest(raw),
        token_last4: raw.last(4)
      )
      token.instance_variable_set(:@plaintext, raw)
      token
    end

    # Global lookup — org is derived from the token, not scoped by the caller.
    def self.authenticate(raw)
      return nil if raw.blank?

      token = find_by(token_digest: digest(raw))
      return nil if token.nil? || token.expired?

      token
    end

    def expired?
      expires_at.present? && expires_at.past?
    end

    # Throttled so the delivery API doesn't write to this row on every request.
    def touch_used!
      return if last_used_at && last_used_at > 10.minutes.ago

      update_column(:last_used_at, Time.current)
    end

    def masked
      "••••#{token_last4}"
    end
  end
end
