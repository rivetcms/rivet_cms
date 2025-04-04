module RivetCms
  class Field < ApplicationRecord
    has_prefix_id :fld, minimum_length: RivetCms.configuration.prefixed_ids_length, salt: RivetCms.configuration.prefixed_ids_salt, alphabet: RivetCms.configuration.prefixed_ids_alphabet

    # Field widths for form layout
    WIDTHS = %w[full half].freeze
    attribute :width, :string, default: 'full'

    belongs_to :content_type
    belongs_to :component, optional: true
    has_many :field_values, dependent: :destroy

    # Define available field types
    FIELD_TYPES = %w[string text integer boolean media relation component markdown]

    validates :name, presence: true, uniqueness: { scope: :content_type_id }
    validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }
    validates :width, inclusion: { in: WIDTHS }
    
    # Default scope to order fields by position
    default_scope { order(position: :asc) }
    
    # Set default position before create
    before_create :set_default_position
    
    # Field type options for select
    def self.field_types_for_select
      [
        ['Short text', 'string'],
        ['Long text', 'text'],
        ['Markdown', 'markdown'],
        ['Number', 'integer'],
        ['True/False', 'boolean'],
        ['Media', 'media'],
        ['Relation', 'relation'],
        ['Component', 'component']
      ]
    end
    
    # Human-readable field type
    def field_type_name
      case field_type
      when 'string' then 'Short text'
      when 'text' then 'Long text'
      when 'integer' then 'Number'
      when 'boolean' then 'True/False'
      else field_type.humanize
      end
    end
    
    # Update positions for a set of fields
    def self.update_positions(ordered_ids)
      return if ordered_ids.blank?
      
      transaction do
        ordered_ids.each_with_index do |prefixed_id, index|
          field = find_by_prefix_id(prefixed_id)
          field&.update_column(:position, index + 1)
        end
      end
    end
    
    after_commit :invalidate_api_docs_cache
    
    private
    
    def set_default_position
      return if position.present?
      
      max_position = content_type.fields.maximum(:position) || 0
      self.position = max_position + 1
    end

    def invalidate_api_docs_cache
      if content_type
        Rails.cache.delete("rivet_cms_api_docs")
      end
    end
  end
end