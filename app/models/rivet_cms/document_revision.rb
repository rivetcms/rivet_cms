module RivetCms
  class ContentInvalidError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super("content is invalid: #{errors.map(&:message).join(', ')}")
    end
  end

  # Raised when content is written or published into a content type that has
  # been removed. Its entries are kept but no longer served, so they must not
  # be edited or republished until the type is restored.
  class RemovedContentTypeError < StandardError; end

  # Raised when a revision is written or published while its entry sits in the
  # trash. Document's kept scope makes revision.document nil, so without this
  # every such path would NoMethodError instead of saying what is wrong.
  class TrashedEntryError < StandardError; end

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

    scope :ordered, -> { order(created_at: :desc, id: :desc) }

    # publisher attributes the snapshot to whoever published it, which is not
    # always the person who last saved the draft.
    def publish!(publisher: nil, publisher_name: nil)
      raise TrashedEntryError, "entry is in the trash; restore it before publishing" if document.nil?
      raise RemovedContentTypeError, "content type was removed; restore it before publishing" unless ContentType.exists?(id: document.content_type_id)

      validator = ContentValidator.new(self).validate
      raise ContentInvalidError, validator.errors unless validator.valid?

      snapshot = transaction do
        published = document.revisions.create!(
          locale: locale,
          schema_version: schema_version,
          author: publisher_name.present? ? publisher : author,
          author_name: publisher_name.presence || author_name,
          state: :published,
          published_at: Time.current
        )
        self.class.copy_owned_into(self, published)
        document.update!(published_revision: published)
        # keep_ids protects the source: republishing an old snapshot as a
        # rollback should not destroy the snapshot it rolled back to.
        RevisionPruner.new(document, keep_ids: [ id ]).prune!
        published
      end

      # Hooks fire only once the write is durable, even under an outer
      # transaction; the gem requires Rails 7.2+ for this guarantee
      ActiveRecord.after_all_transactions_commit { Hooks.run(:publish, snapshot) }
      snapshot
    end

    # Replaces the target draft's owned records with the source's.
    # copy_owned_into alone cannot do this: content values would collide on
    # their per-field uniqueness and relations and component instances would
    # silently duplicate. This is the primitive a revision-history rollback
    # builds on.
    #
    # requires_new opens a savepoint so a failed copy cannot leave the target
    # empty when a caller rescues inside its own transaction. Values for
    # soft-deleted fields are left alone, since the copy cannot restore them
    # and undiscard is expected to recover them.
    def self.restore_owned_into(source, target)
      raise ArgumentError, "cannot restore a revision into itself" if source.id == target.id
      raise ArgumentError, "restore target must be a draft revision" unless target.draft?

      transaction(requires_new: true) do
        target.content_values.where(field_id: Field.select(:id)).destroy_all
        target.relations.where(field_id: Field.select(:id)).destroy_all
        target.component_instances.where(field_id: Field.select(:id)).destroy_all
        copy_owned_into(source, target)
      end
      target
    end

    # Snapshots carry kept-field data only: a soft-deleted field's values may
    # linger on the draft (undiscard recovers them), but copying them would
    # fail the clone's field association, which resolves through Field's
    # kept-only default scope.
    def self.copy_owned_into(source, target)
      source.content_values.where(field_id: Field.select(:id)).find_each do |cv|
        clone = target.content_values.build(field_id: cv.field_id, media_asset_id: cv.media_asset_id)
        ContentValue::VALUE_COLUMNS.each { |col| clone[col] = cv[col] }
        clone.save!
      end

      # Same shape as the kept-field filter: a trashed target would fail the
      # clone's required belongs_to, so it is dropped rather than raising.
      # For restore_owned_into that drop is permanent: the copied draft loses
      # the link even if the target later leaves the trash. A rollback UI
      # should count these and tell the user, as DraftWriter does.
      source.relations.where(field_id: Field.select(:id), target_document_id: Document.select(:id)).find_each do |relation|
        target.relations.create!(
          field_id: relation.field_id,
          target_document_id: relation.target_document_id,
          position: relation.position
        )
      end

      source.component_instances.where(field_id: Field.select(:id)).find_each do |instance|
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
