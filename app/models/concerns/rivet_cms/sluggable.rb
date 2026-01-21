module RivetCms
  module Sluggable
    extend ActiveSupport::Concern

    included do
      before_validation :generate_slug, if: -> { slug.blank? && respond_to?(:name) && name.present? }

      validates :slug, presence: true,
                       format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase alphanumeric with hyphens" }
    end

    private

    def generate_slug
      base_slug = name.parameterize
      self.slug = unique_slug(base_slug)
    end

    def unique_slug(base_slug)
      slug = base_slug
      counter = 1
      scope = self.class.unscoped.where.not(id: id)

      # Scope to organization if acts_as_tenant is used
      if respond_to?(:organization_id) && organization_id.present?
        scope = scope.where(organization_id: organization_id)
      end

      while scope.exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end

      slug
    end
  end
end
