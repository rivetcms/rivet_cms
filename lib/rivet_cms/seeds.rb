# Content-type templates: reusable schema (content types, fields, components,
# categories) that a host app can load into an organization as a starting point.
# Templates live in db/seeds/templates and are applied idempotently, so loading
# the same template twice upserts rather than duplicating — safe in production.
module RivetCms
  module Seeds
    TEMPLATES_PATH = "db/seeds/templates/*.rb".freeze

    class << self
      def registry
        @registry ||= {}
      end

      # Called by each template file to register its definition block.
      def template(name, &block)
        registry[name.to_s] = block
      end

      def available
        load_definitions
        registry.keys.sort
      end

      # Apply one, several, or all templates to an organization. Returns the
      # builders that ran.
      def load!(organization:, only: nil)
        load_definitions
        names = Array(only).map(&:to_s).reject(&:empty?)
        names = registry.keys if names.empty?

        RivetCms::Current.set(organization: organization) do
          names.map { |name| apply(name, organization) }
        end
      end

      def resolve_organization(domain = nil)
        org = if domain.present?
          RivetCms::Organization.find_by(domain: domain)
        else
          RivetCms::Organization.find_by(default: true) || RivetCms::Organization.first
        end
        return org if org

        raise "No organization found#{domain.present? ? " for domain #{domain}" : ''}. Create one first."
      end

      private

      def load_definitions
        return if @loaded

        Dir[RivetCms::Engine.root.join(TEMPLATES_PATH)].sort.each { |file| require file }
        @loaded = true
      end

      def apply(name, organization)
        block = registry.fetch(name) { raise ArgumentError, "unknown template: #{name}" }
        builder = Builder.new(organization)
        builder.instance_eval(&block)
        builder.commit
      end
    end

    # Collects field definitions inside a content_type/component block.
    class FieldSet
      SCALAR_TYPES = %i[string text rich_text markdown integer decimal enumeration boolean image video file date datetime].freeze

      attr_reader :definitions

      def initialize
        @definitions = []
      end

      SCALAR_TYPES.each do |type|
        define_method(type) do |key, **opts|
          add(type, key, opts)
        end
      end

      def reference(key, to:, **opts)
        add(:reference, key, opts.merge(to: to))
      end

      def component(key, use:, **opts)
        add(:component, key, opts.merge(use: use))
      end

      private

      def add(type, key, opts)
        @definitions << opts.merge(type: type, key: key.to_s)
      end
    end

    # Applies a template's declarations to the database for one organization.
    class Builder
      def initialize(organization)
        @organization = organization
        @categories = []
        @components = []
        @content_types = []
        @category_index = {}
        @component_index = {}
        @content_type_index = {}
      end

      def category(name, slug: nil, system: false, position: 0)
        @categories << { name: name, slug: slug || name.parameterize, system: system, position: position }
      end

      def component(name, category:, slug: nil, description: nil, &block)
        fields = FieldSet.new
        fields.instance_eval(&block) if block
        @components << { name: name, slug: slug || name.parameterize, category: category, description: description, fields: fields.definitions }
      end

      def content_type(name, slug:, description: nil, single: false, &block)
        fields = FieldSet.new
        fields.instance_eval(&block) if block
        @content_types << { name: name, slug: slug, description: description, single: single, fields: fields.definitions }
      end

      # Shells first (so references and component fields can resolve regardless of
      # declaration order), then fields.
      def commit
        RivetCms::ApplicationRecord.transaction do
          @categories.each { |attrs| upsert_category(attrs) }
          component_records = @components.map { |attrs| upsert_component(attrs) }
          content_type_records = @content_types.map { |attrs| upsert_content_type(attrs) }

          @components.each_with_index { |attrs, i| build_fields(component_records[i], attrs[:fields]) }
          @content_types.each_with_index { |attrs, i| build_fields(content_type_records[i], attrs[:fields]) if content_type_records[i] }
        end
        self
      end

      private

      def upsert_category(attrs)
        category = RivetCms::Category.find_or_initialize_by(organization: @organization, slug: attrs[:slug])
        category.name = attrs[:name]
        category.system = attrs[:system] if attrs.key?(:system)
        category.position = attrs[:position] || category.position || 0
        category.save!
        @category_index[attrs[:slug]] = category
        @category_index[attrs[:name]] = category
        category
      end

      def resolve_category(name)
        @category_index[name] || @category_index[name.to_s.parameterize] ||
          upsert_category(name: name, slug: name.to_s.parameterize)
      end

      def upsert_component(attrs)
        component = RivetCms::Component.find_or_initialize_by(organization: @organization, slug: attrs[:slug])
        component.name = attrs[:name]
        component.description = attrs[:description]
        component.category = resolve_category(attrs[:category])
        component.save!
        @component_index[attrs[:slug]] = component
        @component_index[attrs[:name]] = component
        component
      end

      def upsert_content_type(attrs)
        # with_discarded so a removed type is recognised rather than colliding
        # with its reserved slug. A removal is deliberate, so seeding leaves it
        # alone instead of silently restoring it and its entries.
        content_type = RivetCms::ContentType.with_discarded.find_or_initialize_by(organization: @organization, slug: attrs[:slug])
        # Skipped entirely, not just left undiscarded: keeping it out of the
        # index stops build_fields rewriting its schema. Reference fields
        # pointing at it are dropped by build_fields rather than seeded broken.
        return nil if content_type.discarded?

        content_type.name = attrs[:name]
        content_type.description = attrs[:description]
        content_type.single = attrs[:single] || false
        content_type.save!
        @content_type_index[attrs[:slug]] = content_type
        content_type
      end

      def build_fields(owner, definitions)
        # A reference to a removed type cannot be seeded, so its definition is
        # dropped alongside the field it would have produced; layout_rows pairs
        # the two lists positionally and must not see a gap.
        definitions = definitions.reject { |definition| removed_reference?(definition) }
        return if definitions.empty?

        owner_key = owner.is_a?(RivetCms::ContentType) ? :content_type_id : :component_id
        records = definitions.map { |definition| upsert_field(owner, owner_key, definition) }
        RivetCms::Field.update_layout!(layout_rows(definitions, records))
      end

      def removed_reference?(definition)
        return false unless definition[:type] == :reference

        lookup_content_type(definition[:to]).nil?
      end

      def upsert_field(owner, owner_key, definition)
        field = RivetCms::Field.with_discarded.find_or_initialize_by(owner_key => owner.id, key: definition[:key])
        field.assign_attributes(field_attributes(definition).merge(organization: @organization, deleted_at: nil))
        field.save!
        field
      end

      def field_attributes(definition)
        attributes = {
          label: definition[:label] || definition[:key].titleize,
          field_type: definition[:type],
          required: definition.fetch(:required, false),
          description: definition[:description],
          width: definition[:width] == :half ? "half" : "full",
          config: definition[:config] || {},
          min_items: definition[:min_items],
          max_items: definition[:max_items]
        }

        case definition[:type]
        when :reference
          attributes[:config] = { "content_type_id" => lookup_content_type(definition[:to]).id }
        when :component
          attributes[:config] = { "component_id" => lookup_component(definition[:use]).id }
        end

        attributes
      end

      # nil when the target exists but has been removed; raises only when the
      # template names a type that was never seeded at all.
      def lookup_content_type(slug)
        found = @content_type_index[slug] || RivetCms::ContentType.find_by(organization: @organization, slug: slug)
        return found if found
        return nil if RivetCms::ContentType.with_discarded.exists?(organization: @organization, slug: slug)

        raise ArgumentError, "reference target content type not found: #{slug}"
      end

      def lookup_component(name)
        @component_index[name] || @component_index[name.to_s.parameterize] ||
          RivetCms::Component.find_by(organization: @organization, slug: name.to_s.parameterize) ||
          raise(ArgumentError, "component not found: #{name}")
      end

      # Pair consecutive half-width fields onto one row; everything else gets its own.
      def layout_rows(definitions, records)
        rows = []
        i = 0
        while i < definitions.length
          if definitions[i][:width] == :half && definitions[i + 1] && definitions[i + 1][:width] == :half
            rows << [ records[i].id, records[i + 1].id ]
            i += 2
          else
            rows << [ records[i].id ]
            i += 1
          end
        end
        rows
      end
    end
  end
end
