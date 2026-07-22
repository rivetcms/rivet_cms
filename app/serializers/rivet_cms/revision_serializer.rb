module RivetCms
  class RevisionSerializer
    RICH_TEXT_TAGS = %w[p br strong em b i u s del a img ul ol li h1 h2 h3 h4 h5 h6 blockquote pre code hr].freeze
    RICH_TEXT_ATTRS = %w[href src alt title class target rel width height style].freeze

    def initialize(revision)
      @revision = revision
    end

    def as_json(*)
      return nil if @revision.nil?

      document = @revision.document
      {
        id: document.prefix_id,
        slug: document.slug,
        content_type: document.content_type.slug,
        state: @revision.state,
        data: serialize_owner(@revision, document.content_type.fields.kept)
      }
    end

    private

    def serialize_owner(owner, fields)
      loaded = OwnerData.new(owner)

      fields.each_with_object({}) do |field, data|
        data[field.key] = serialize_field(loaded, field)
      end
    end

    def serialize_field(loaded, field)
      case field.field_type
      when "reference"
        collapse(field, loaded.relations(field).map { |relation| reference_json(relation) })
      when "component"
        collapse(field, loaded.component_instances(field).map { |instance| serialize_owner(instance, instance.component.fields.kept) })
      when "image", "video", "file"
        attachment_json(loaded.value(field)&.media_asset)
      when "rich_text"
        sanitize(loaded.value(field)&.value)
      else
        loaded.value(field)&.value
      end
    end

    def reference_json(relation)
      { id: relation.target_document.prefix_id, slug: relation.target_document.slug }
    end

    def attachment_json(asset)
      return nil unless asset

      { id: asset.prefix_id, filename: asset.filename, content_type: asset.content_type, byte_size: asset.byte_size, url: asset.url }
    end

    def collapse(field, items)
      field.max_items == 1 ? items.first : items
    end

    def sanitize(html)
      return nil if html.blank?

      ActionController::Base.helpers.sanitize(html.to_s, tags: RICH_TEXT_TAGS, attributes: RICH_TEXT_ATTRS)
    end

    # Loads an owner's values, relations, and component instances once
    # and serves per-field lookups from memory.
    class OwnerData
      def initialize(owner)
        @owner = owner
      end

      def value(field)
        values_by_field[field.id]
      end

      def relations(field)
        relations_by_field.fetch(field.id, [])
      end

      def component_instances(field)
        instances_by_field.fetch(field.id, [])
      end

      private

      def values_by_field
        @values_by_field ||= @owner.content_values
          .includes(:field, media_asset: { file_attachment: :blob })
          .index_by(&:field_id)
      end

      def relations_by_field
        @relations_by_field ||= @owner.relations
          .includes(:target_document).order(:position).group_by(&:field_id)
      end

      def instances_by_field
        @instances_by_field ||= @owner.component_instances
          .includes(component: :fields).order(:position).group_by(&:field_id)
      end
    end
  end
end
