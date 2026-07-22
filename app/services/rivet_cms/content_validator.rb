module RivetCms
  class ContentValidator
    Error = Struct.new(:field_key, :message)

    attr_reader :errors

    def initialize(revision)
      @revision = revision
      @errors = []
    end

    def valid?
      @errors.empty?
    end

    def validate
      validate_owner(@revision, content_type.fields.kept)
      self
    end

    def messages
      @errors.map { |e| "#{e.field_key} #{e.message}" }
    end

    private

    def content_type
      @revision.document.content_type
    end

    def validate_owner(owner, fields)
      values_by_field = owner.content_values.includes(:field, :media_asset).index_by(&:field_id)
      relation_counts = owner.relations.group(:field_id).count
      instances_by_field = owner.component_instances.includes(component: :fields).group_by(&:field_id)

      fields.each do |field|
        case field.field_type
        when "reference"
          validate_cardinality(field, relation_counts.fetch(field.id, 0))
        when "component"
          validate_component_field(field, instances_by_field.fetch(field.id, []))
        when "image", "video", "file"
          validate_attachment_field(field, values_by_field[field.id]&.media_asset)
        else
          validate_scalar_field(field, values_by_field[field.id]&.value)
        end
      end
    end

    def validate_scalar_field(field, value)
      return add(field, "is required") if field.required? && blank_value?(value)
      return if blank_value?(value)

      validate_config_constraints(field, value)
    end

    def validate_component_field(field, instances)
      validate_cardinality(field, instances.size)
      instances.each { |instance| validate_owner(instance, instance.component.fields.kept) }
    end

    def validate_attachment_field(field, asset)
      return add(field, "is required") if field.required? && asset.nil?
      return unless asset

      validate_media(field, asset)
    end

    def validate_cardinality(field, count)
      minimum = field.min_items || (field.required? ? 1 : 0)
      add(field, "requires at least #{minimum}") if count < minimum
      add(field, "allows at most #{field.max_items}") if field.max_items && count > field.max_items
    end

    def validate_config_constraints(field, value)
      config = field.config || {}

      if field.integer? || field.decimal?
        min = numeric_bound(config["min"])
        max = numeric_bound(config["max"])
        add(field, "is too small") if min && value < min
        add(field, "is too large") if max && value > max
      elsif field.enumeration?
        add(field, "is not a valid choice") unless Array(config["choices"]).include?(value)
      else
        length = value.to_s.length
        min_length = numeric_bound(config["min_length"])&.to_i
        max_length = numeric_bound(config["max_length"])&.to_i
        add(field, "is too short") if min_length && length < min_length
        add(field, "is too long") if max_length && length > max_length
        validate_pattern(field, value, config["pattern"])
      end
    end

    def validate_pattern(field, value, pattern)
      return if pattern.blank?
      return unless field.string? || field.text?

      add(field, "does not match the required format") unless SafePattern.match?(pattern, value)
    end

    # Config values arrive from the admin UI as strings; comparing them
    # against typed values directly would raise.
    def numeric_bound(raw)
      return nil if raw.blank?

      Float(raw)
    rescue ArgumentError, TypeError
      nil
    end

    def validate_media(field, asset)
      config = field.config || {}
      add(field, "has a disallowed file type") unless allowed_extension?(config["allowed_types"], asset)

      max_mb = config["max_size_mb"].presence&.to_f
      add(field, "is too large (max #{max_mb} MB)") if max_mb && asset.byte_size.to_i > max_mb * 1.megabyte
    end

    def allowed_extension?(allowed, asset)
      list = normalize_extensions(allowed)
      return true if list.empty?

      list.include?(normalize_extension(File.extname(asset.filename.to_s)))
    end

    def normalize_extensions(allowed)
      list = allowed.is_a?(::String) ? allowed.split(",") : Array(allowed)
      list.map { |ext| normalize_extension(ext) }.reject(&:empty?)
    end

    def normalize_extension(ext)
      ext = ext.to_s.strip.delete_prefix(".").downcase
      ext == "jpeg" ? "jpg" : ext
    end

    def add(field, message)
      @errors << Error.new(field.key, message)
    end

    def blank_value?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end
