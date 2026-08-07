module RivetCms
  # Builds an OpenAPI 3 document describing the delivery API for an organization's
  # content types. Field types map to JSON Schema; references/components/media
  # expand into nested schemas.
  class OpenApiGenerator
    # content_types/components narrow the document to a permitted subset;
    # nil means all. Excluded types must not be referenced either, or the
    # document would carry $refs to schemas it does not contain.
    def initialize(organization, base_url: "/api", content_types: nil, components: nil)
      @organization = organization
      @base_url = base_url
      @content_types = content_types
      @components = components
    end

    def as_json(*)
      content_types = (@content_types || @organization.content_types.order(:name)).to_a

      {
        openapi: "3.0.3",
        info: { title: "RivetCms Delivery API", version: "1.0.0" },
        servers: [ { url: @base_url } ],
        components: {
          securitySchemes: { bearerAuth: { type: "http", scheme: "bearer" } },
          schemas: content_types.each_with_object({}) { |ct, acc| acc[schema_name(ct)] = document_schema(ct) }
        },
        security: [ { bearerAuth: [] } ],
        paths: content_types.each_with_object({}) { |ct, acc| add_paths(acc, ct) }
      }
    end

    private

    def add_paths(paths, content_type)
      item = "#{@base_url}/#{content_type.slug}"
      ref = { "$ref" => "#/components/schemas/#{schema_name(content_type)}" }

      paths["#{item}"] = {
        get: {
          summary: "List #{content_type.name}",
          parameters: list_params,
          responses: { "200" => { description: "A page of documents", content: json_content(list_schema(ref)) } }
        }
      }
      paths["#{item}/{slug}"] = {
        get: {
          summary: "Fetch one #{content_type.name} by slug",
          parameters: [
            { name: "slug", in: "path", required: true, schema: { type: "string" } },
            { name: "preview", in: "query", required: false, schema: { type: "boolean" },
              description: "Requires a preview-scoped token; returns the draft revision." },
            populate_param,
            fields_param
          ],
          responses: { "200" => { description: "A document", content: json_content(ref) }, "404" => { description: "Not found" } }
        }
      }
    end

    def list_params
      [
        { name: "page", in: "query", schema: { type: "integer", default: 1 } },
        { name: "per_page", in: "query", schema: { type: "integer", default: 25, maximum: 100 } },
        { name: "sort", in: "query", schema: { type: "string" },
          description: "Field/column, prefix - for descending (e.g. -published_at)." },
        populate_param,
        fields_param
      ]
    end

    def populate_param
      { name: "populate", in: "query", schema: { type: "string" },
        description: "Comma-separated reference field keys to expand one level into full documents, or * for all." }
    end

    def fields_param
      { name: "fields", in: "query", schema: { type: "string" },
        description: "Comma-separated field keys to include in data; also limits which populated fields appear." }
    end

    def list_schema(item_ref)
      {
        type: "object",
        properties: {
          data: { type: "array", items: item_ref },
          meta: { type: "object", properties: {
            page: { type: "integer" }, per_page: { type: "integer" },
            total: { type: "integer" }, total_pages: { type: "integer" }
          } }
        }
      }
    end

    def document_schema(content_type)
      {
        type: "object",
        properties: {
          id: { type: "string" },
          slug: { type: "string" },
          content_type: { type: "string" },
          state: { type: "string", enum: %w[draft published archived] },
          data: { type: "object", properties: content_type.fields.kept.ordered.each_with_object({}) { |f, acc| acc[f.key] = field_schema(f) } }
        }
      }
    end

    def field_schema(field)
      case field.field_type
      when "integer" then { type: "integer" }
      when "decimal" then { type: "number" }
      when "boolean" then { type: "boolean" }
      when "date" then { type: "string", format: "date" }
      when "datetime" then { type: "string", format: "date-time" }
      when "enumeration" then enumeration_schema(field)
      when "reference" then reference_schema(field)
      when "component" then component_schema(field)
      when "image", "video", "file"
        { type: "object", nullable: true, properties: {
          id: { type: "integer" }, filename: { type: "string" }, content_type: { type: "string" },
          byte_size: { type: "integer" }, title: { type: "string", nullable: true },
          alt: { type: "string", nullable: true }, description: { type: "string", nullable: true },
          url: { type: "string" }
        } }
      when "string", "text" then string_schema(field)
      else { type: "string" }
      end
    end

    def enumeration_schema(field)
      choices = Array(field.config&.dig("choices"))
      choices.any? ? { type: "string", enum: choices } : { type: "string" }
    end

    def string_schema(field)
      pattern = field.config&.dig("pattern")
      pattern.present? ? { type: "string", pattern: pattern } : { type: "string" }
    end

    # Shallow {id, slug} by default; when the field's configured target resolves,
    # a oneOf with the target schema documents the populated shape.
    # A target outside the generated subset stays shallow: emitting its $ref
    # would point at a schema this document does not contain.
    def reference_schema(field)
      shallow = { type: "object", properties: { id: { type: "string" }, slug: { type: "string" } } }
      target = @organization.content_types.find_by(id: field.config&.dig("content_type_id"))
      inner = target && included_type_ids.include?(target.id) ? { oneOf: [ shallow, { "$ref" => "#/components/schemas/#{schema_name(target)}" } ] } : shallow
      collapse(field, inner)
    end

    # Same rule: a component outside the subset renders as an opaque object
    # rather than leaking its field structure.
    def component_schema(field)
      component = Component.find_by(id: field.config&.dig("component_id"), organization_id: field.organization_id)
      inner = if component && included_component_ids.include?(component.id)
        { type: "object", properties: component.fields.kept.ordered.each_with_object({}) { |f, acc| acc[f.key] = field_schema(f) } }
      else
        { type: "object" }
      end
      collapse(field, inner)
    end

    def included_type_ids
      @included_type_ids ||= (@content_types || @organization.content_types).map(&:id).to_set
    end

    def included_component_ids
      @included_component_ids ||= (@components || @organization.components).map(&:id).to_set
    end

    def collapse(field, schema)
      field.max_items == 1 ? schema : { type: "array", items: schema }
    end

    def json_content(schema)
      { "application/json" => { schema: schema } }
    end

    # Distinct slugs can produce the same camelized name (top-10 and top10
    # both yield Top10), so names are deduped once per generation.
    def schema_name(content_type)
      schema_names.fetch(content_type.id)
    end

    def schema_names
      @schema_names ||= @organization.content_types.order(:id).each_with_object({}) do |ct, map|
        base = ct.slug.split("-").map(&:capitalize).join
        name = base
        suffix = 2
        while map.value?(name)
          name = "#{base}_#{suffix}"
          suffix += 1
        end
        map[ct.id] = name
      end
    end
  end
end
