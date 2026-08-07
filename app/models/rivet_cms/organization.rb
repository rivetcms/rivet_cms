module RivetCms
  class Organization < ApplicationRecord
    # Organization has no prefix id, so prefixed_ids does not patch its
    # has_many finders; extend explicitly so find accepts prefixed ids.
    PREFIXED_FINDERS = PrefixedIds::Finder::ClassMethods

    # content_types is soft-delete scoped, so dependent: :destroy would skip
    # discarded rows and leave them holding the FK; destroy those explicitly.
    # Documents are destroyed first because ContentType restricts on them.
    has_many :content_types, dependent: :destroy, extend: PREFIXED_FINDERS
    before_destroy :destroy_all_content, prepend: true
    has_many :components, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :categories, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :media_assets, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :api_tokens, dependent: :destroy, extend: PREFIXED_FINDERS

    validates :name, presence: true
    validates :domain, presence: true, uniqueness: true
    validates :subdomain, uniqueness: true, allow_blank: true

    private

    # Destroying an organization is a deliberate, total removal, so it clears
    # the content that ContentType otherwise refuses to cascade, including
    # rows behind the soft-delete scope.
    def destroy_all_content
      types = ContentType.with_discarded.where(organization_id: id)
      # organization_id, not the type join: that column is what holds the FK
      # Either column can hold the link if data has drifted, so cover both
      documents = Document.where(organization_id: id).or(Document.where(content_type_id: types.select(:id)))
      # Relations point at documents by foreign key, so incoming links have to
      # go before their targets or the cascade order decides whether we crash.
      Relation.where(target_document_id: documents.select(:id)).delete_all
      documents.find_each(&:destroy!)
      types.find_each(&:destroy!)
    rescue ActiveRecord::RecordNotDestroyed => error
      # Otherwise destroy returns false with an empty errors hash
      errors.add(:base, "could not remove content: #{error.message}")
      throw :abort
    end
  end
end
