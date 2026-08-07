module RivetCms
  # Bulk-loads everything RevisionSerializer needs for a set of revisions in a
  # constant number of queries, regardless of page size. Components cannot nest,
  # so the owner tree is bounded: revision -> component instances -> values/relations.
  # When populate_fields are given, target documents' revisions are loaded and
  # preloaded the same way (one level deep).
  class RevisionPreloader
    def initialize(revisions, populate_fields: [], preview: false)
      @revisions = Array(revisions).compact
      @populate_field_ids = populate_fields.map(&:id).to_set
      @preview = preview
      @values = {}
      @relations = {}
      @instances = {}
      @fields_by_content_type = {}
      @fields_by_component = {}
      @target_revision_by_document_id = {}
      load_all
    end

    def document_for(revision)
      revision.document
    end

    def fields_for_content_type(content_type_id)
      @fields_by_content_type[content_type_id] || []
    end

    def fields_for_component(component_id)
      @fields_by_component[component_id] || []
    end

    def value(owner, field)
      @values.dig(owner_key(owner), field.id)
    end

    def relations(owner, field)
      @relations.dig(owner_key(owner), field.id) || []
    end

    def component_instances(owner, field)
      @instances.dig(owner_key(owner), field.id) || []
    end

    def target_revision(document_id)
      @target_revision_by_document_id[document_id]
    end

    private

    def owner_key(owner)
      [ owner.class.name, owner.id ]
    end

    def load_all
      return if @revisions.empty?

      ActiveRecord::Associations::Preloader.new(records: @revisions, associations: { document: :content_type }).call
      load_fields_for_content_types(@revisions.map { |revision| revision.document.content_type_id })
      load_owned(@revisions)
      load_populate_targets
    end

    def load_fields_for_content_types(content_type_ids)
      missing = content_type_ids.uniq - @fields_by_content_type.keys
      return if missing.empty?

      Field.where(content_type_id: missing).ordered
        .group_by(&:content_type_id)
        .each { |ct_id, fields| @fields_by_content_type[ct_id] = fields }
      missing.each { |ct_id| @fields_by_content_type[ct_id] ||= [] }
    end

    def load_owned(owners)
      load_values_and_relations(owners)

      instances = ComponentInstance
        .where(owner_type: owners.first.class.name, owner_id: owners.map(&:id))
        .order(:position).includes(:component).to_a
      group_owned(instances, @instances)

      component_ids = instances.map(&:component_id).uniq
      if component_ids.any?
        Field.where(component_id: component_ids).ordered
          .group_by(&:component_id)
          .each { |comp_id, fields| @fields_by_component[comp_id] = fields }
      end

      load_values_and_relations(instances) if instances.any?
    end

    def load_values_and_relations(owners)
      owner_type = owners.first.class.name
      owner_ids = owners.map(&:id)

      values = ContentValue
        .where(owner_type: owner_type, owner_id: owner_ids)
        .includes(:field, media_asset: { file_attachment: :blob }).to_a
      values.group_by { |value| [ value.owner_type, value.owner_id ] }.each do |key, group|
        @values[key] = group.index_by(&:field_id)
      end

      relations = Relation
        .where(owner_type: owner_type, owner_id: owner_ids)
        .order(:position).includes(target_document: :content_type).to_a
      group_owned(relations, @relations)
    end

    def group_owned(records, store)
      records.group_by { |record| [ record.owner_type, record.owner_id ] }.each do |key, group|
        store[key] = group.group_by(&:field_id)
      end
    end

    def load_populate_targets
      return if @populate_field_ids.empty?

      targets = @revisions.flat_map { |revision|
        (@relations[owner_key(revision)] || {})
          .select { |field_id, _| @populate_field_ids.include?(field_id) }
          .values.flatten.map(&:target_document)
      }.compact.uniq # a target can be trashed, leaving the association nil

      revision_id_by_document = targets.each_with_object({}) do |document, map|
        revision_id = @preview ? (document.draft_revision_id || document.published_revision_id) : document.published_revision_id
        map[document.id] = revision_id if revision_id
      end
      return if revision_id_by_document.empty?

      target_revisions = DocumentRevision.where(id: revision_id_by_document.values).index_by(&:id)
      documents_by_id = targets.index_by(&:id)

      revision_id_by_document.each do |document_id, revision_id|
        revision = target_revisions[revision_id]
        next unless revision

        revision.association(:document).target = documents_by_id[document_id]
        @target_revision_by_document_id[document_id] = revision
      end

      loaded = @target_revision_by_document_id.values
      load_fields_for_content_types(loaded.map { |revision| revision.document.content_type_id })
      load_owned(loaded)
    end
  end
end
