module RivetCms
  class Field < ApplicationRecord
    include SoftDeletable

    has_prefix_id :fld
    acts_as_tenant :organization

    belongs_to :organization, optional: true
    belongs_to :content_type, optional: true
    belongs_to :component, optional: true
    has_many :content_values, dependent: :destroy

    enum :field_type, {
      string: 0,
      text: 1,
      rich_text: 2,
      markdown: 3,
      integer: 4,
      boolean: 5,
      image: 6,
      video: 7,
      file: 8,
      reference: 9,
      component: 10
    }

    enum :width, { full: "full", half: "half" }, prefix: true

    validates :name, presence: true
    validates :name, uniqueness: { scope: :content_type_id, conditions: -> { where(deleted_at: nil) } }, if: -> { content_type_id.present? }
    validates :name, uniqueness: { scope: :component_id, conditions: -> { where(deleted_at: nil) } }, if: -> { component_id.present? }
    validates :field_type, presence: true
    validate :belongs_to_one_owner

    before_create :set_default_position
    before_create :set_default_row

    scope :ordered, -> { order(row: :asc, position: :asc) }

    # Human-readable field type labels for UI
    FIELD_TYPE_LABELS = {
      "string" => "Short text",
      "text" => "Long text",
      "rich_text" => "Rich text",
      "markdown" => "Markdown",
      "integer" => "Number",
      "boolean" => "True/False",
      "image" => "Image",
      "video" => "Video",
      "file" => "File",
      "reference" => "Reference",
      "component" => "Component"
    }.freeze

    def field_type_label
      FIELD_TYPE_LABELS[field_type] || field_type.humanize
    end

    def self.field_types_for_select
      FIELD_TYPE_LABELS.map { |value, label| [label, value] }
    end

    def attachment?
      image? || video? || file?
    end

    def self.reorder!(ordered_ids)
      transaction do
        ordered_ids.each_with_index do |id, index|
          where(id: id).update_all(position: index)
        end
      end
    end

    # Update layout with row structure
    # rows_config: array of arrays, each inner array contains field IDs for that row
    # e.g., [["fld_abc"], ["fld_def", "fld_ghi"], ["fld_jkl"]]
    def self.update_layout!(rows_config)
      transaction do
        rows_config.each_with_index do |field_ids, row_index|
          field_ids.each_with_index do |field_id, position_in_row|
            where(id: field_id).update_all(row: row_index, position: position_in_row)
          end
        end
      end
    end

    # Get the other field paired in the same row (if any)
    def paired_field
      return nil unless width_half?
      return nil unless content_type_id.present?

      self.class.kept
          .where(content_type_id: content_type_id, row: row, width: "half")
          .where.not(id: id)
          .first
    end

    def paired?
      paired_field.present?
    end

    # Move this field to its own new row
    def unpair!
      return unless paired?

      move_to_own_row!
    end

    # Move this field to its own new row
    def move_to_own_row!
      max_row = self.class.where(content_type_id: content_type_id).maximum(:row) || 0
      update!(row: max_row + 1, position: 0)
    end

    # Normalize layout for a content type - ONLY fixes invalid states:
    # - Full-width fields sharing a row with other fields
    # - More than 2 fields in a row
    # Does NOT auto-pair half-width fields
    def self.normalize_layout!(content_type_id)
      transaction do
        fields_by_row = where(content_type_id: content_type_id).kept.group_by(&:row)

        fields_by_row.each do |row_num, row_fields|
          # Check for full-width fields sharing a row
          full_width_fields = row_fields.select(&:width_full?)
          half_width_fields = row_fields.select(&:width_half?)

          # If a full-width field is sharing a row, move it to its own row
          if full_width_fields.any? && row_fields.size > 1
            full_width_fields.each do |field|
              field.move_to_own_row!
            end
          end

          # If more than 2 half-width fields in a row, move extras to own rows
          if half_width_fields.size > 2
            half_width_fields[2..].each do |field|
              field.move_to_own_row!
            end
          end
        end
      end
    end

    # Pair this field with another field on the same row
    def pair_with!(other_field)
      return unless width_half? && other_field.width_half?
      return if paired? || other_field.paired?

      other_field.update!(row: row, position: 1)
    end

    private

    def belongs_to_one_owner
      has_content_type = content_type_id.present? || content_type.present?
      has_component = component_id.present? || component.present?

      if has_content_type && has_component
        errors.add(:base, "Field cannot belong to both content_type and component")
      elsif !has_content_type && !has_component
        errors.add(:base, "Field must belong to either content_type or component")
      end
    end

    def set_default_position
      return if position.present? && position > 0

      max_position = if content_type_id.present?
        self.class.with_discarded.where(content_type_id: content_type_id).maximum(:position) || 0
      elsif component_id.present?
        self.class.with_discarded.where(component_id: component_id).maximum(:position) || 0
      else
        0
      end

      self.position = max_position + 1
    end

    def set_default_row
      # Always set a new row for new fields (don't skip if row is 0)
      return if persisted? && row.present?

      max_row = if content_type_id.present?
        self.class.with_discarded.where(content_type_id: content_type_id).maximum(:row) || -1
      elsif component_id.present?
        self.class.with_discarded.where(component_id: component_id).maximum(:row) || -1
      else
        -1
      end

      self.row = max_row + 1
    end
  end
end
