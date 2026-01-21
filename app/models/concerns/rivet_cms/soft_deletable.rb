module RivetCms
  module SoftDeletable
    extend ActiveSupport::Concern

    included do
      scope :kept, -> { where(deleted_at: nil) }
      scope :discarded, -> { where.not(deleted_at: nil) }

      default_scope { kept }
    end

    class_methods do
      def with_discarded
        unscope(where: :deleted_at)
      end
    end

    def discard
      update(deleted_at: Time.current)
    end

    def discard!
      update!(deleted_at: Time.current)
    end

    def undiscard
      update(deleted_at: nil)
    end

    def undiscard!
      update!(deleted_at: nil)
    end

    def discarded?
      deleted_at.present?
    end

    def kept?
      deleted_at.nil?
    end
  end
end
