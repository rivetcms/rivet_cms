module RivetCms
  class ContentInvalidError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super("content is invalid: #{errors.map(&:message).join(', ')}")
    end
  end

  class DocumentRevision < ApplicationRecord
    has_prefix_id :rev

    belongs_to :document
    # The reference stays optional so deleting a host user doesn't orphan or
    # block revisions; author_name is the durable attribution and is required.
    belongs_to :author, polymorphic: true, optional: true

    validates :author_name, presence: true

    has_many :content_values, as: :owner, dependent: :destroy
    has_many :relations, as: :owner, dependent: :destroy
    has_many :component_instances, as: :owner, dependent: :destroy

    enum :state, { draft: 0, published: 1, archived: 2 }

    scope :ordered, -> { order(created_at: :desc) }

    def publish!
      validator = ContentValidator.new(self).validate
      raise ContentInvalidError, validator.errors unless validator.valid?

      snapshot = transaction do
        published = document.revisions.create!(
          locale: locale,
          schema_version: schema_version,
          author: author,
          author_name: author_name,
          state: :published,
          published_at: Time.current
        )
        self.class.copy_owned_into(self, published)
        document.update!(published_revision: published)
        published
      end

      # Hooks fire only once the write is durable, even under an outer
      # transaction; the gem requires Rails 7.2+ for this guarantee
      ActiveRecord.after_all_transactions_commit { Hooks.run(:publish, snapshot) }
      snapshot
    end

    def self.copy_owned_into(source, target)
      source.content_values.find_each do |cv|
        clone = target.content_values.build(field_id: cv.field_id, media_asset_id: cv.media_asset_id)
        ContentValue::VALUE_COLUMNS.each { |col| clone[col] = cv[col] }
        clone.save!
      end

      source.relations.find_each do |relation|
        target.relations.create!(
          field_id: relation.field_id,
          target_document_id: relation.target_document_id,
          position: relation.position
        )
      end

      source.component_instances.find_each do |instance|
        clone = target.component_instances.create!(
          field_id: instance.field_id,
          component_id: instance.component_id,
          position: instance.position
        )
        copy_owned_into(instance, clone)
      end
    end
  end
end
