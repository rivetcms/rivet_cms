module RivetCms
  class ContentValue < ApplicationRecord
    belongs_to :content
    belongs_to :field
    belongs_to :value, polymorphic: true, dependent: :destroy

    validates :content, presence: true
    validates :field, presence: true
    validates :value, presence: true

    # Returns the actual value from the polymorphic association
    def field_value
      return nil unless value.present?

      if field&.rich_text?
        sanitize_html(value.value)
      else
        value.value
      end
    end

    # Factory method to set a value for a content/field pair
    def self.set_value(content, field, raw_value)
      content_value = content.content_values.find_or_initialize_by(field: field)
      value_class = value_class_for(field.field_type)

      # Handle existing value or create new
      if content_value.value.is_a?(value_class)
        update_existing_value(content_value, raw_value)
      else
        content_value.value&.destroy
        content_value.value = create_value(value_class, field, raw_value)
      end

      content_value.save!
      content_value
    end

    # Maps field types to value classes
    def self.value_class_for(field_type)
      case field_type.to_s
      when "string"
        FieldValues::String
      when "text", "rich_text", "markdown"
        FieldValues::Text
      when "integer"
        FieldValues::Integer
      when "boolean"
        FieldValues::Boolean
      when "image", "video", "file"
        FieldValues::Attachment
      else
        raise ArgumentError, "Unsupported field type: #{field_type}"
      end
    end

    private

    def sanitize_html(html)
      return "" if html.blank?

      ActionController::Base.helpers.sanitize(
        html.to_s,
        tags: %w[strong em b i p br ul ol li h1 h2 h3 h4 h5 h6 blockquote a img pre code],
        attributes: %w[href src alt title class]
      )
    end

    def self.create_value(klass, field, raw_value)
      value_obj = klass.new
      value_obj.required = field.required?

      if klass == FieldValues::Attachment
        value_obj.attachment_type = field.field_type
        value_obj.file = raw_value if raw_value.present?
      else
        value_obj.value = coerce_value(klass, raw_value)
      end

      value_obj.save!
      value_obj
    end

    def self.update_existing_value(content_value, raw_value)
      value_obj = content_value.value

      if value_obj.is_a?(FieldValues::Attachment)
        value_obj.file = raw_value if raw_value.present?
      else
        value_obj.value = coerce_value(value_obj.class, raw_value)
      end

      value_obj.save!
    end

    def self.coerce_value(klass, raw_value)
      case klass.name
      when "RivetCms::FieldValues::String", "RivetCms::FieldValues::Text"
        raw_value.to_s
      when "RivetCms::FieldValues::Integer"
        raw_value.present? ? raw_value.to_i : 0
      when "RivetCms::FieldValues::Boolean"
        ActiveModel::Type::Boolean.new.cast(raw_value)
      else
        raw_value
      end
    end
  end
end
