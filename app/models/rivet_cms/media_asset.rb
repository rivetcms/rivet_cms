module RivetCms
  class MediaAsset < ApplicationRecord
    include OrganizationScoped

    has_prefix_id :media

    has_one_attached :file

    enum :kind, { image: 0, video: 1, file: 2 }

    validates :file, presence: true
    validate :file_size_within_limit
    validate :file_type_allowed

    before_save :cache_file_metadata

    scope :recent, -> { order(created_at: :desc) }

    def url
      return nil unless file.attached?

      helpers = Rails.application.routes.url_helpers
      if RivetCms.media_host.present?
        helpers.rails_blob_url(file, host: RivetCms.media_host)
      else
        helpers.rails_blob_path(file, only_path: true)
      end
    end

    # Rich text embeds media by URL (which contains the blob signed id),
    # so field references alone don't tell us an asset is in use.
    def embedded_in_content?
      return false unless file.attached?

      pattern = file.blob.signed_id.gsub(/[!%_]/) { |c| "!#{c}" }
      ContentValue.where("text_value LIKE ? ESCAPE '!'", "%#{pattern}%").exists?
    end

    def self.kind_for(content_type)
      case content_type.to_s
      when /\Aimage\// then :image
      when /\Avideo\// then :video
      else :file
      end
    end

    private

    def file_size_within_limit
      limit = RivetCms.max_upload_size
      return unless limit && file.attached?
      return if file.byte_size <= limit

      errors.add(:file, "is too large (max #{ActiveSupport::NumberHelper.number_to_human_size(limit)})")
    end

    def file_type_allowed
      allowed = RivetCms.allowed_media_types
      return unless allowed && file.attached?

      blob = file.blob
      blob.identify_without_saving unless blob.identified?
      return if allowed.include?(blob.content_type)

      errors.add(:file, "type #{blob.content_type} is not allowed")
    end

    def cache_file_metadata
      return unless file.attached?

      blob = file.blob
      blob.identify_without_saving unless blob.identified?

      self.filename = blob.filename.to_s
      self.content_type = blob.content_type
      self.byte_size = blob.byte_size
      self.kind = self.class.kind_for(blob.content_type)
    end
  end
end
