module RivetCms
  module FieldValues
    class Attachment < Base
      self.table_name = "rivet_cms_field_values_attachments"

      has_one_attached :file

      enum :attachment_type, { image: 0, video: 1, file: 2 }

      validates :file, presence: true, if: :required?
      validate :validate_content_type, if: -> { file.attached? }
      validate :validate_file_size, if: -> { file.attached? }

      # Returns a hash with attachment details
      def value
        return nil unless file.attached?

        base_info = {
          url: file_url,
          filename: file.filename.to_s,
          content_type: file.content_type,
          byte_size: file.byte_size,
          created_at: file.created_at
        }

        case attachment_type
        when "image"
          base_info.merge(image_info)
        when "video"
          base_info.merge(video_info)
        else
          base_info
        end
      end

      def value=(file_data)
        return file.purge if file_data.nil? && file.attached?
        return if file_data.blank?

        case file_data
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
          file.attach(file_data)
        when ::String
          attach_from_base64(file_data) if file_data.start_with?("data:")
        when Hash
          attach_from_blob(file_data) if file_data["id"].present?
        end
      end

      private

      def file_url
        Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true)
      rescue StandardError
        "/rails/active_storage/blobs/redirect/#{file.signed_id}/#{file.filename}"
      end

      def image_info
        return {} unless file.variable?

        {
          thumbnail_url: variant_url(:thumbnail),
          medium_url: variant_url(:medium),
          width: file.metadata[:width],
          height: file.metadata[:height]
        }
      end

      def video_info
        { duration: file.metadata[:duration] }
      end

      def variant_url(size)
        variants = {
          thumbnail: { resize_to_limit: [ 150, 150 ] },
          medium: { resize_to_limit: [ 800, 800 ] }
        }

        variant = file.variant(variants[size])
        Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
      rescue StandardError
        nil
      end

      def attach_from_base64(data)
        content_type = data.match(/data:([^;]+)/)[1]
        base64_data = data.sub(/data:[^;]+;base64,/, "")
        decoded_data = Base64.decode64(base64_data)

        extension = content_type.split("/").last
        filename = "#{attachment_type}_#{Time.current.to_i}.#{extension}"

        file.attach(
          io: StringIO.new(decoded_data),
          filename: filename,
          content_type: content_type
        )
      end

      def attach_from_blob(data)
        blob = ActiveStorage::Blob.find(data["id"])
        file.attach(blob)
      rescue ActiveRecord::RecordNotFound
        errors.add(:file, "blob not found")
      end

      def validate_content_type
        allowed = case attachment_type
        when "image"
          %w[image/jpeg image/png image/gif image/webp image/svg+xml]
        when "video"
          %w[video/mp4 video/webm video/quicktime]
        when "file"
          %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
             application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
             text/plain application/zip]
        else
          []
        end

        unless allowed.include?(file.content_type)
          errors.add(:file, "has an invalid content type: #{file.content_type}")
        end
      end

      def validate_file_size
        max_size = case attachment_type
        when "image" then 10.megabytes
        when "video" then 100.megabytes
        when "file" then 50.megabytes
        else 10.megabytes
        end

        if file.byte_size > max_size
          errors.add(:file, "is too large (max #{max_size / 1.megabyte}MB)")
        end
      end
    end
  end
end
