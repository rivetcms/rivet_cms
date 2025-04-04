module RivetCms
  class ContentType < ApplicationRecord
    has_prefix_id :ctype, minimum_length: RivetCms.configuration.prefixed_ids_length, salt: RivetCms.configuration.prefixed_ids_salt, alphabet: RivetCms.configuration.prefixed_ids_alphabet

    has_many :contents, dependent: :destroy
    has_many :fields, dependent: :destroy

    validates :name, presence: true
    validates :slug, presence: true
    validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }
    
    # Default to collection type (is_single = false)
    after_initialize :set_default_type, if: :new_record?

    after_commit :invalidate_api_docs_cache

    def collection?
      !is_single
    end

    def single?
      is_single
    end

    # For compatibility with existing views
    def is_collection
      !is_single
    end

    private

    def set_default_type
      self.is_single = false if self.is_single.nil?
    end

    def invalidate_api_docs_cache
      Rails.cache.delete("rivet_cms_api_docs")
    end
  end
end
