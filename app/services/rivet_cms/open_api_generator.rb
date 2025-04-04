module RivetCms
  class OpenApiGenerator
    class << self
      def generate
        Rails.cache.fetch("rivet_cms_api_docs", expires_in: 1.hour) do
          generate_schema
        end
      end

      private

      def generate_schema
        schema = {
          "openapi" => "3.0.1",
          "info" => {
            "title" => "RivetCMS API",
            "version" => "1.0.0",
            "description" => "API documentation for content types"
          },
          "paths" => generate_paths,
          "components" => {
            "schemas" => generate_schemas,
            "securitySchemes" => {
              "bearerAuth" => {
                "type" => "http",
                "scheme" => "bearer",
                "bearerFormat" => "JWT"
              }
            }
          },
          "security" => [
            { "bearerAuth" => [] }
          ]
        }

        deep_stringify_keys(schema)
      end

      def deep_stringify_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            result[key.to_s] = deep_stringify_keys(value)
          end
        when Array
          obj.map { |item| deep_stringify_keys(item) }
        else
          obj
        end
      end

      def generate_paths
        paths = {}
        
        ContentType.all.each do |content_type|
          if content_type.is_single
            paths.merge!(generate_single_type_paths(content_type))
          else
            paths.merge!(generate_collection_type_paths(content_type))
          end
        end

        paths
      end

      def generate_single_type_paths(content_type)
        {
          "/api/v1/#{content_type.slug}" => {
            "get" => {
              "tags" => [content_type.name],
              "summary" => "Get #{content_type.name}",
              "responses" => {
                "200" => {
                  "description" => "Returns the #{content_type.name}",
                  "content" => {
                    "application/json" => {
                      "schema" => { "$ref" => "#/components/schemas/#{content_type.slug}" }
                    }
                  }
                }
              }
            }
          }
        }
      end

      def generate_collection_type_paths(content_type)
        {
          "/api/v1/#{content_type.slug}" => {
            "get" => {
              "tags" => [content_type.name],
              "summary" => "List all #{content_type.name.pluralize}",
              "parameters" => [
                {
                  "name" => "page",
                  "in" => "query",
                  "description" => "Page number for pagination",
                  "schema" => { "type" => "integer", "default" => 1 },
                  "required" => false
                },
                {
                  "name" => "per_page",
                  "in" => "query",
                  "description" => "Number of items per page",
                  "schema" => { "type" => "integer", "default" => 25 },
                  "required" => false
                }
              ],
              "responses" => {
                "200" => {
                  "description" => "Returns list of #{content_type.name.pluralize}",
                  "content" => {
                    "application/json" => {
                      "schema" => {
                        "type" => "object",
                        "properties" => {
                          "data" => {
                            "type" => "array",
                            "items" => { "$ref" => "#/components/schemas/#{content_type.slug}" }
                          },
                          "meta" => {
                            "type" => "object",
                            "properties" => {
                              "current_page" => { "type" => "integer" },
                              "total_pages" => { "type" => "integer" },
                              "total_count" => { "type" => "integer" }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "/api/v1/#{content_type.slug}/{id}" => {
            "get" => {
              "tags" => [content_type.name],
              "summary" => "Get a specific #{content_type.name}",
              "parameters" => [
                {
                  "name" => "id",
                  "in" => "path",
                  "required" => true,
                  "schema" => { "type" => "string" },
                  "description" => "The ID of the #{content_type.name} to retrieve"
                }
              ],
              "responses" => {
                "200" => {
                  "description" => "Returns the #{content_type.name}",
                  "content" => {
                    "application/json" => {
                      "schema" => { "$ref" => "#/components/schemas/#{content_type.slug}" }
                    }
                  }
                },
                "404" => {
                  "description" => "#{content_type.name} not found"
                }
              }
            }
          }
        }
      end

      def generate_schemas
        schemas = {}
        
        ContentType.all.each do |content_type|
          schemas[content_type.slug] = generate_content_type_schema(content_type)
        end

        schemas
      end

      def generate_content_type_schema(content_type)
        {
          "type" => "object",
          "properties" => generate_properties(content_type)
        }
      end

      def generate_properties(content_type)
        properties = {
          "id" => { "type" => "string" },
          "title" => { "type" => "string" },
          "slug" => { "type" => "string" },
          "status" => { 
            "type" => "string",
            "enum" => ["draft", "published", "archived"]
          },
          "created_at" => { "type" => "string", "format" => "date-time" },
          "updated_at" => { "type" => "string", "format" => "date-time" }
        }

        content_type.fields.each do |field|
          properties[field.name] = field_type_to_schema(field)
        end

        properties
      end

      def field_type_to_schema(field)
        case field.field_type
        when 'string', 'text'
          { "type" => "string" }
        when 'integer'
          { "type" => "integer" }
        when 'boolean'
          { "type" => "boolean" }
        when 'media'
          {
            "type" => "object",
            "properties" => {
              "url" => { "type" => "string" },
              "filename" => { "type" => "string" },
              "content_type" => { "type" => "string" }
            }
          }
        when 'relation'
          {
            "type" => "object",
            "properties" => {
              "id" => { "type" => "string" },
              "title" => { "type" => "string" }
            }
          }
        when 'component'
          {
            "type" => "object",
            "properties" => {
              "id" => { "type" => "string" },
              "type" => { "type" => "string" },
              "fields" => { "type" => "object" }
            }
          }
        else
          { "type" => "string" }
        end
      end
    end
  end
end 