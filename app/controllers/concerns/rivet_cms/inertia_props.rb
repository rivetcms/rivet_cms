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
          edit: edit_content_type_path(content_type),
          update: content_type_path(content_type),
          fields: content_type_fields_path(content_type),
          update_layout: update_layout_content_type_fields_path(content_type)
        }
      }
    end

    def field_props(field)
      content_type = field.content_type

      {
        id: field.id,
        param: field.to_param,
        name: field.name,
        field_type: field.field_type,
        field_type_label: field.field_type_label,
        description: field.description,
        required: field.required?,
        width: field.width,
        row: field.row,
        position: field.position,
        paired: field.paired?,
        options: field.options || {},
        paths: {
          update: content_type_field_path(content_type, field),
          destroy: content_type_field_path(content_type, field),
          toggle_width: toggle_width_content_type_field_path(content_type, field),
          pair: pair_content_type_field_path(content_type, field),
          unpair: unpair_content_type_field_path(content_type, field)
        }
      }
    end

    def component_props(component)
      {
        id: component.id,
        param: component.to_param,
        name: component.name,
        slug: component.slug,
        description: component.description,
        repeatable: component.repeatable?,
        category_id: component.category_id,
        category_name: component.category&.name,
        paths: {
          show: component_path(component),
          edit: edit_component_path(component),
          update: component_path(component)
        }
      }
    end

    def category_props(category)
      { id: category.id, name: category.name }
    end
  end
end
