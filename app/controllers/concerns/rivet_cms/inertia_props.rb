module RivetCms
  # Serializes models into plain hashes for Inertia page props.
  # Paths are included server-side so the React app never needs to know
  # where the engine is mounted.
  module InertiaProps
    private

    def content_type_props(content_type)
      {
        id: content_type.id,
        param: content_type.to_param,
        name: content_type.name,
        slug: content_type.slug,
        description: content_type.description,
        single: content_type.single?,
        paths: {
          show: content_type_path(content_type),
          update: content_type_path(content_type),
          destroy: content_type_path(content_type),
          fields: content_type_fields_path(content_type),
          update_layout: update_layout_content_type_fields_path(content_type),
          documents: content_type_documents_path(content_type),
          new_document: new_content_type_document_path(content_type)
        }
      }
    end

    def field_props(field)
      {
        id: field.id,
        param: field.to_param,
        key: field.key,
        label: field.label,
        field_type: field.field_type,
        field_type_label: field.field_type_label,
        description: field.description,
        required: field.required?,
        width: field.width,
        row: field.row,
        position: field.position,
        paired: field.paired?,
        min_items: field.min_items,
        max_items: field.max_items,
        config: field.config || {},
        paths: field_paths(field)
      }
    end

    def field_paths(field)
      if field.component_id
        component = field.component
        {
          update: component_field_path(component, field),
          destroy: component_field_path(component, field),
          toggle_width: toggle_width_component_field_path(component, field),
          pair: pair_component_field_path(component, field),
          unpair: unpair_component_field_path(component, field)
        }
      else
        content_type = field.content_type
        {
          update: content_type_field_path(content_type, field),
          destroy: content_type_field_path(content_type, field),
          toggle_width: toggle_width_content_type_field_path(content_type, field),
          pair: pair_content_type_field_path(content_type, field),
          unpair: unpair_content_type_field_path(content_type, field)
        }
      end
    end

    def document_props(document)
      {
        id: document.id,
        param: document.to_param,
        slug: document.slug,
        published: document.published_revision_id.present?,
        paths: {
          edit: edit_content_type_document_path(document.content_type, document),
          update: content_type_document_path(document.content_type, document),
          publish: publish_content_type_document_path(document.content_type, document),
          destroy: content_type_document_path(document.content_type, document)
        }
      }
    end

    def entry_field_props(field)
      {
        key: field.key,
        label: field.label,
        field_type: field.field_type,
        field_type_label: field.field_type_label,
        description: field.description,
        required: field.required?,
        width: field.width,
        row: field.row,
        position: field.position,
        min_items: field.min_items,
        max_items: field.max_items,
        config: field.config || {},
        component: embedded_component_props(field)
      }
    end

    def embedded_component_props(field)
      return nil unless field.field_type == "component"

      component = Component.find_by(id: field.config&.dig("component_id"), organization_id: field.organization_id)
      return nil unless component

      { id: component.id, name: component.name, fields: component.fields.kept.ordered.map { |f| entry_field_props(f) } }
    end

    def draft_values(revision)
      return {} if revision.nil?

      owner_values(revision, revision.document.content_type.fields.kept)
    end

    def owner_values(owner, fields)
      values_by_field = owner.content_values
        .includes(:field, media_asset: { file_attachment: :blob })
        .index_by(&:field_id)
      relations_by_field = owner.relations.order(:position).group_by(&:field_id)
      instances_by_field = owner.component_instances.includes(component: :fields).order(:position).group_by(&:field_id)

      fields.each_with_object({}) do |field, values|
        values[field.key] = editable_value(field, values_by_field, relations_by_field, instances_by_field)
      end
    end

    def editable_value(field, values_by_field, relations_by_field, instances_by_field)
      case field.field_type
      when "reference"
        relations_by_field.fetch(field.id, []).map(&:target_document_id)
      when "component"
        instances_by_field.fetch(field.id, []).map do |instance|
          { values: owner_values(instance, instance.component.fields.kept) }
        end
      when "image", "video", "file"
        media_asset_json(values_by_field[field.id]&.media_asset)
      else
        values_by_field[field.id]&.value
      end
    end

    def media_asset_json(asset)
      return nil unless asset

      {
        id: asset.id,
        kind: asset.kind,
        filename: asset.filename,
        content_type: asset.content_type,
        byte_size: asset.byte_size,
        title: asset.title,
        alt: asset.alt,
        description: asset.description,
        created_at: asset.created_at&.iso8601,
        url: asset.url,
        thumbnail_url: asset.thumbnail_url,
        paths: { update: media_asset_path(asset), destroy: media_asset_path(asset) }
      }
    end

    def api_token_json(token)
      {
        id: token.id,
        name: token.name,
        scope: token.scope,
        masked: token.masked,
        last_used_at: token.last_used_at,
        expires_at: token.expires_at,
        created_at: token.created_at,
        paths: { destroy: api_token_path(token) }
      }
    end

    def component_props(component)
      {
        id: component.id,
        param: component.to_param,
        name: component.name,
        slug: component.slug,
        description: component.description,
        category_id: component.category_id,
        category_name: component.category&.name,
        paths: {
          show: component_path(component),
          update: component_path(component),
          destroy: component_path(component),
          fields: component_fields_path(component),
          update_layout: update_layout_component_fields_path(component)
        }
      }
    end

    def category_props(category)
      { id: category.id, name: category.name }
    end
  end
end
