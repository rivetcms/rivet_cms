module RivetCms
  # Builds an OpenAPI 3 document describing the delivery API for an organization's
  # content types. Field types map to JSON Schema; references/components/media
  # expand into nested schemas.
  class OpenApiGenerator
    def initialize(organization, base_url: "/api")
      @organization = organization
      @base_url = base_url
    end

    def as_json(*)
      content_types = @organization.content_types.order(:name).to_a

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
              description: "Requires a preview-scoped token; returns the draft revision." }
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
          description: "Field/column, prefix - for descending (e.g. -published_at)." }
      ]
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
      when "boolean" then { type: "boolean" }
      when "date" then { type: "string", format: "date" }
      when "datetime" then { type: "string", format: "date-time" }
      when "reference" then collapse(field, { type: "object", properties: { id: { type: "string" }, slug: { type: "string" } } })
      when "component" then component_schema(field)
      when "image", "video", "file"
        { type: "object", nullable: true, properties: {
          id: { type: "integer" }, filename: { type: "string" }, content_type: { type: "string" },
          byte_size: { type: "integer" }, url: { type: "string" }
        } }
      else { type: "string" }
      end
    end

    def component_schema(field)
      component = Component.find_by(id: field.config&.dig("component_id"), organization_id: field.organization_id)
      inner = if component
        { type: "object", properties: component.fields.kept.ordered.each_with_object({}) { |f, acc| acc[f.key] = field_schema(f) } }
      else
        { type: "object" }
      end
      collapse(field, inner)
    end

    def collapse(field, schema)
      field.max_items == 1 ? schema : { type: "array", items: schema }
    end

    def json_content(schema)
      { "application/json" => { schema: schema } }
    end

    def schema_name(content_type)
      content_type.slug.split(/[-_]/).map(&:capitalize).join
    end
  end
end
