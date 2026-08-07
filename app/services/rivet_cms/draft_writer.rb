module RivetCms
  class DraftWriter
    def initialize(revision)
      @revision = revision
    end

    def write(values)
      content_type = @revision.document.content_type
      raise RemovedContentTypeError, "content type was removed; restore it before editing" if content_type.nil?

      write_values(@revision, content_type.fields.kept, values)
      @revision
    end

    private

    def write_values(owner, fields, values)
      fields_by_key = fields.index_by(&:key)

      values.each do |key, raw|
        field = fields_by_key[key.to_s]
        next unless field

        case field.field_type
        when "reference"
          write_relations(owner, field, raw)
        when "component"
          write_components(owner, field, raw)
        else
          write_scalar(owner, field, raw)
        end
      end
    end

    def write_scalar(owner, field, raw)
      value = owner.content_values.find_or_initialize_by(field: field)
      value.value = raw
      value.save!
    end

    def write_relations(owner, field, ids)
      owner.relations.where(field_id: field.id).destroy_all

      Array(ids).reject(&:blank?).each_with_index do |target_id, index|
        owner.relations.create!(field: field, target_document_id: target_id, position: index)
      end
    end

    def write_components(owner, field, entries)
      component = Component.find_by(id: field.config&.dig("component_id"), organization_id: field.organization_id)
      return unless component

      owner.component_instances.where(field_id: field.id).destroy_all

      Array(entries).each_with_index do |entry, index|
        instance = owner.component_instances.create!(field: field, component: component, position: index)
        write_values(instance, component.fields.kept, entry["values"] || {})
      end
    end
  end
end
