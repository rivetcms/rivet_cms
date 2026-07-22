module RivetCms
  module TypedValue
    extend ActiveSupport::Concern

    VALUE_COLUMNS = %i[
      string_value text_value integer_value boolean_value
      decimal_value datetime_value date_value json_value
    ].freeze

    SCALAR_COLUMN = {
      "string" => :string_value,
      "text" => :text_value,
      "rich_text" => :text_value,
      "markdown" => :text_value,
      "integer" => :integer_value,
      "boolean" => :boolean_value,
      "date" => :date_value,
      "datetime" => :datetime_value
    }.freeze

    def value
      return media_asset if field&.attachment?

      column = value_column
      column ? self[column] : nil
    end

    def value=(raw)
      if field&.attachment?
        self.media_asset = MediaAsset.find_by(id: extract_media_asset_id(raw))
        return
      end

      column = value_column
      self[column] = raw if column
    end

    private

    def extract_media_asset_id(raw)
      raw = raw["id"] || raw[:id] if raw.is_a?(Hash)
      raw.presence
    end

    def value_column
      SCALAR_COLUMN[field&.field_type]
    end
  end
end
