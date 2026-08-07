module RivetCms
  class ContentType < ApplicationRecord
    include Sluggable

    has_prefix_id :ctype
    include OrganizationScoped
    include HasFields
    include SoftDeletable

    # Deleting a type must never cascade into content. Discarding hides the
    # type and its entries; a real destroy is refused while entries exist, so
    # there is no path from one click to a wiped library.
    has_many :documents, dependent: :restrict_with_error
    # documents is soft-delete scoped, so restrict_with_error cannot see a
    # trashed entry; without this a destroy would slip past it into an FK error.
    before_destroy :restrict_when_entries_remain, prepend: true

    validates :name, presence: true
    # The unique index spans removed rows too, so a removed type keeps its slug
    # reserved and restoring one can never collide with something created since.
    validates :slug, uniqueness: { scope: :organization_id }
    validate :slug_not_held_by_removed_type
    validates :single, inclusion: { in: [ true, false ] }

    scope :singles, -> { where(single: true) }
    scope :collections, -> { where(single: false) }

    def collection?
      !single?
    end

    private

    def restrict_when_entries_remain
      return unless Document.with_discarded.where(content_type_id: id).exists?

      errors.add(:base, "Cannot delete record because dependent documents exist")
      throw :abort
    end

    # Rails' uniqueness validator ignores the kept default scope, so a slug held
    # by a removed type does produce "has already been taken". Declared after it
    # so that baffling message can be replaced with one that says what to do.
    def slug_not_held_by_removed_type
      return if slug.blank?
      return if persisted? && !slug_changed?
      return unless self.class.with_discarded.discarded.exists?(organization_id: organization_id, slug: slug)

      errors.delete(:slug, :taken)
      errors.add(:slug, "belongs to a removed content type; restore that type instead of recreating it")
    end
  end
end
