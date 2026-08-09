module RivetCms
  # Admin account for built-in authentication mode. Dormant when the host
  # wires its own auth: nothing reads this table unless RivetCms.builtin_auth?
  #
  # CE has no roles: every authenticated user can do everything, so this model
  # carries only identity and sign-in state. Role-based and per-record
  # permissions are a Pro feature that installs its own policy through the
  # can? seam and its own tables.
  #
  # Accounts are always created by an existing user (or the first-run setup
  # screen); there is no self-registration. A user created without a password
  # is pending: they finish through a signed set-password link and cannot sign
  # in before that. Deactivation, never deletion: audit events and content
  # attribution reference these rows.
  class User < ApplicationRecord
    include OrganizationScoped

    has_prefix_id :usr

    has_secure_password validations: false

    before_validation { self.email = email.to_s.strip.downcase }

    validates :name, presence: true
    validates :email, presence: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP },
                      uniqueness: { scope: :organization_id }
    validates :password, length: { minimum: 8 }, allow_nil: true
    validate :password_within_bcrypt_limit

    scope :active, -> { where(active: true) }

    # Invalidated automatically when the password changes (salt rotates)
    generates_token_for :password_setup, expires_in: 3.days do
      password_salt
    end

    def pending?
      password_digest.nil?
    end

    def status
      return "inactive" unless active?
      return "pending" if pending?

      "active"
    end

    def can_sign_in?
      active? && !pending?
    end

    private

    # BCrypt silently truncates at 72 bytes, which would make two long
    # passwords sharing a prefix interchangeable; refuse instead
    def password_within_bcrypt_limit
      errors.add(:password, "is too long (maximum is 72 bytes)") if password && password.bytesize > 72
    end
  end
end
