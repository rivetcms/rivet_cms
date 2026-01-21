module RivetCms
  class Content < ApplicationRecord
    include Sluggable

    has_prefix_id :cnt
    acts_as_tenant :organization

    belongs_to :organization, optional: true
    belongs_to :content_type
    has_many :content_values, dependent: :destroy

    enum :status, { draft: 0, published: 1, archived: 2 }

    validates :slug, uniqueness: { scope: :organization_id }

    scope :recent, -> { order(created_at: :desc) }

    # Returns the value for a specific field
    def value_for(field)
      field_record = field.is_a?(Field) ? field : content_type.fields.with_discarded.find_by(id: field)
      return nil unless field_record

      content_value = content_values.find_by(field: field_record)
      content_value&.field_value
    end

    # Returns a hash of all field values
    def all_values(include_discarded_fields: false)
      fields = include_discarded_fields ? content_type.fields.with_discarded : content_type.fields
      fields.each_with_object({}) do |field, result|
        result[field.name] = value_for(field)
      end
    end

    # Returns a suitable title for display
    def title
      # Try to find a title field
      title_field = content_type.fields.with_discarded.find_by(name: "title")
      if title_field
        title_value = value_for(title_field)
        return title_value if title_value.present?
      end

      # Fall back to slug
      slug
    end

    # Status transition methods
    def publish!
      update!(status: :published, published_at: Time.current)
    end

    def unpublish!
      update!(status: :draft, unpublished_at: Time.current)
    end

    def archive!
      update!(status: :archived, unpublished_at: Time.current)
    end

    # Sets field values from a hash
    def set_values(values_hash)
      values_hash.each do |field_name, value|
        field = content_type.fields.find_by(name: field_name)
        next unless field

        ContentValue.set_value(self, field, value)
      end
    end
  end
end
