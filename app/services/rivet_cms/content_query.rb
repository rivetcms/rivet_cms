module RivetCms
  # Builds the published-document query for one content type: whitelisted sort,
  # date-range filters, pagination clamp, and populate/fields validation.
  # Shared by the delivery API controller and the Ruby content helpers so both
  # access paths keep identical semantics.
  class ContentQuery
    class Error < StandardError; end

    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
    DOCUMENT_SORTS = { "created_at" => :created_at, "updated_at" => :updated_at, "slug" => :slug }.freeze

    def initialize(content_type, sort: nil, filters: {}, page: nil, per_page: nil, populate: nil, fields: nil)
      @content_type = content_type
      @sort = sort
      @filters = normalize_filters(filters)
      @page = page
      @per_page = per_page
      @populate = populate
      @fields = fields
    end

    # Kaminari page of published documents, ordered and filtered.
    def documents
      base = @content_type.documents.where.not(published_revision_id: nil).includes(:published_revision)
      ordered(filtered(base)).page(@page).per(per_page)
    end

    # Validated reference Field records to expand, already dropped when a
    # fields selection excludes them so their targets are never preloaded.
    def populate_fields
      @populate_fields ||= begin
        populate = resolve_populate
        keys = field_keys
        keys ? populate.select { |field| keys.include?(field.key) } : populate
      end
    end

    def field_keys
      return @field_keys if defined?(@field_keys)

      keys = normalize_list(@fields)
      return @field_keys = nil if keys.empty?

      unknown = keys - @content_type.fields.kept.pluck(:key)
      raise Error, "unknown field: #{unknown.first}" if unknown.any?

      @field_keys = keys
    end

    private

    def per_page
      requested = @per_page.to_i
      requested = DEFAULT_PER_PAGE if requested <= 0
      requested.clamp(1, MAX_PER_PAGE)
    end

    def reference_fields
      @reference_fields ||= @content_type.fields.kept.reference.ordered.to_a
    end

    def resolve_populate
      return reference_fields if @populate == :all || @populate.to_s.strip == "*"

      normalize_list(@populate).map do |key|
        reference_fields.find { |field| field.key == key } ||
          raise(Error, "cannot populate field: #{key}")
      end
    end

    # Accepts the API's comma-separated string or a Ruby array of keys/symbols.
    def normalize_list(raw)
      list = raw.is_a?(Array) ? raw.map(&:to_s) : raw.to_s.split(",")
      list.map(&:strip).reject(&:blank?)
    end

    # Bounds may use string or symbol gte/lte keys; values may be strings or
    # Date/Time objects.
    def normalize_filters(filters)
      (filters || {}).each_with_object({}) do |(key, bounds), normalized|
        next unless bounds.is_a?(Hash)

        gte = bounds["gte"] || bounds[:gte]
        lte = bounds["lte"] || bounds[:lte]
        normalized[key.to_s] = { "gte" => gte, "lte" => lte } if gte.present? || lte.present?
      end
    end

    def ordered(scope)
      key, direction = parse_sort
      return scope.order(DOCUMENT_SORTS.fetch(key) => direction) if DOCUMENT_SORTS.key?(key)

      if key == "published_at"
        return scope
          .joins("INNER JOIN rivet_cms_document_revisions pub ON pub.id = rivet_cms_documents.published_revision_id")
          .order(Arel.sql("pub.published_at #{direction}"))
      end

      field = date_field(key)
      raise Error, "unknown sort field: #{key}" if field.nil?

      scope.joins(field_join(field, "cv_sort")).order(Arel.sql("cv_sort.#{date_column(field)} #{direction}"))
    end

    def filtered(scope)
      @filters.each_with_index do |(key, bounds), index|
        field = date_field(key)
        raise Error, "unknown filter field: #{key}" if field.nil?

        alias_name = "cv_f#{index}"
        scope = scope.joins(field_join(field, alias_name))
        scope = apply_bound(scope, field, alias_name, ">=", bounds["gte"]) if bounds["gte"].present?
        scope = apply_bound(scope, field, alias_name, "<=", bounds["lte"]) if bounds["lte"].present?
      end
      scope
    end

    def parse_sort
      raw = @sort.to_s
      return [ "published_at", :desc ] if raw.blank?

      raw.start_with?("-") ? [ raw[1..], :desc ] : [ raw, :asc ]
    end

    def field_join(field, alias_name)
      <<~SQL.squish
        LEFT JOIN rivet_cms_content_values #{alias_name}
          ON #{alias_name}.owner_type = 'RivetCms::DocumentRevision'
         AND #{alias_name}.owner_id = rivet_cms_documents.published_revision_id
         AND #{alias_name}.field_id = #{field.id.to_i}
      SQL
    end

    def apply_bound(scope, field, alias_name, operator, value)
      scope.where("#{alias_name}.#{date_column(field)} #{operator} ?", parse_date(field, value))
    end

    def date_field(key)
      @content_type.fields.kept.find_by(key: key, field_type: [ :date, :datetime ])
    end

    def date_column(field)
      field.date? ? "date_value" : "datetime_value"
    end

    def parse_date(field, value)
      return value if value.respond_to?(:strftime)

      parsed = field.date? ? Date.parse(value) : Time.zone.parse(value)
      raise Error, "invalid date: #{value}" if parsed.nil?

      parsed
    rescue ArgumentError, TypeError, Date::Error
      raise Error, "invalid date: #{value}"
    end
  end
end
