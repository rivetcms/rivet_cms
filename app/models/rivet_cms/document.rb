module RivetCms
  class Document < ApplicationRecord
    include OrganizationScoped

    has_prefix_id :doc

    belongs_to :content_type
    belongs_to :published_revision, class_name: "RivetCms::DocumentRevision", optional: true
    belongs_to :draft_revision, class_name: "RivetCms::DocumentRevision", optional: true
    has_many :revisions, class_name: "RivetCms::DocumentRevision", dependent: :destroy

    before_validation :assign_singleton_key
    before_destroy :detach_revisions, prepend: true

    validates :slug, presence: true, uniqueness: { scope: :content_type_id }
    validates :singleton_key, uniqueness: { scope: :content_type_id }, if: -> { singleton_key.present? }
    validate :content_type_in_same_organization

    scope :recent, -> { order(created_at: :desc) }
    scope :search, ->(query) { where("LOWER(slug) LIKE ?", "%#{sanitize_sql_like(query.downcase)}%") }

    private

    def assign_singleton_key
      self.singleton_key = content_type&.single? ? "singleton" : nil
    end

    def detach_revisions
      update_columns(published_revision_id: nil, draft_revision_id: nil)
    end

    def content_type_in_same_organization
      return if content_type.nil? || organization.nil?
      return if content_type.organization == organization

      errors.add(:content_type, "must belong to the same organization")
    end
  end
end
