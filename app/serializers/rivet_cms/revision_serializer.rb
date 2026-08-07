module RivetCms
  class RevisionSerializer
    RICH_TEXT_TAGS = %w[p br strong em b i u s del a img ul ol li h1 h2 h3 h4 h5 h6 blockquote pre code hr].freeze
    RICH_TEXT_ATTRS = %w[href src alt title class target rel width height style].freeze

    # fields: root-level key whitelist (nil = all). populate: reference Field
    # records to expand one level deep. preview: serve draft targets and skip
    # the published-only relation filter. preload: a shared RevisionPreloader
    # (built automatically for single-revision use).
    def initialize(revision, fields: nil, populate: [], preview: false, preload: nil)
      @revision = revision
      @field_keys = fields
      @populate = populate
      @populate_field_ids = populate.map(&:id).to_set
      @preview = preview
      @preload = preload
    end

    def as_json(*)
      return nil if @revision.nil?

      @preload ||= RevisionPreloader.new([ @revision ], populate_fields: @populate, preview: @preview)
      document = @preload.document_for(@revision)
      fields = @preload.fields_for_content_type(document.content_type_id)
      fields = fields.select { |field| @field_keys.include?(field.key) } if @field_keys

      {
        id: document.prefix_id,
        slug: document.slug,
        content_type: document.content_type.slug,
        state: @revision.state,
        data: serialize_owner(@revision, fields, root: true)
      }
    end

    private

    def serialize_owner(owner, fields, root:)
      fields.each_with_object({}) do |field, data|
        data[field.key] = serialize_field(owner, field, root: root)
      end
    end

    def serialize_field(owner, field, root:)
      case field.field_type
      when "reference"
        serialize_reference(owner, field, root: root)
      when "component"
        collapse(field, @preload.component_instances(owner, field).map { |instance|
          serialize_owner(instance, @preload.fields_for_component(instance.component_id), root: false)
        })
      when "image", "video", "file"
        attachment_json(@preload.value(owner, field)&.media_asset)
      when "rich_text"
        sanitize(@preload.value(owner, field)&.value)
      else
        scalar_json(@preload.value(owner, field)&.value)
      end
    end

    # ActiveSupport encodes BigDecimal as a JSON string; the API promises a number.
    def scalar_json(value)
      value.is_a?(BigDecimal) ? value.to_f : value
    end

    def serialize_reference(owner, field, root:)
      relations = visible_relations(@preload.relations(owner, field))

      if root && @populate_field_ids.include?(field.id)
        collapse(field, relations.filter_map { |relation| populated_json(relation) })
      else
        collapse(field, relations.map { |relation| reference_json(relation) })
      end
    end

    # Published scope must not reveal draft-only documents, even as {id, slug}.
    # Targets whose content type has been removed are hidden the same way, in
    # both scopes: their type is no longer served, so neither are they.
    def visible_relations(relations)
      # A target can be missing entirely (trashed entry) or belong to a removed
      # type; either way it is no longer served, so neither is the reference.
      visible = relations.reject { |relation| relation.target_document.nil? || relation.target_document.content_type.nil? }
      return visible if @preview

      visible.reject { |relation| relation.target_document.published_revision_id.nil? }
    end

    def reference_json(relation)
      { id: relation.target_document.prefix_id, slug: relation.target_document.slug }
    end

    def populated_json(relation)
      target = relation.target_document
      revision = @preload.target_revision(target.id)
      return nil if revision.nil?

      {
        id: target.prefix_id,
        slug: target.slug,
        content_type: target.content_type.slug,
        state: revision.state,
        data: serialize_owner(revision, @preload.fields_for_content_type(target.content_type_id), root: false)
      }
    end

    def attachment_json(asset)
      return nil unless asset

      { id: asset.prefix_id, filename: asset.filename, content_type: asset.content_type, byte_size: asset.byte_size,
        title: asset.title, alt: asset.alt, description: asset.description, url: asset.url }
    end

    def collapse(field, items)
      field.max_items == 1 ? items.first : items
    end

    def sanitize(html)
      return nil if html.blank?

      ActionController::Base.helpers.sanitize(html.to_s, tags: RICH_TEXT_TAGS, attributes: RICH_TEXT_ATTRS)
    end
  end
end
