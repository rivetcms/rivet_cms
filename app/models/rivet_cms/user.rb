module RivetCms
  class User < ApplicationRecord
    acts_as_tenant :organization

    has_secure_password

    belongs_to :organization, optional: true
    belongs_to :invited_by, class_name: "RivetCms::User", optional: true
    belongs_to :deleted_by, class_name: "RivetCms::User", optional: true

    enum :role, { member: 0, admin: 1, owner: 2 }

    validates :name, presence: true
    validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 8 }, if: -> { password.present? }

    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    scope :pending_invitation, -> { where.not(invited_at: nil).where(accepted_at: nil) }

    def soft_delete(by:)
      update(deleted_at: Time.current, deleted_by: by)
    end

    def deleted?
      deleted_at.present?
    end

    def pending_invitation?
      invited_at.present? && accepted_at.nil?
    end
  end
end
