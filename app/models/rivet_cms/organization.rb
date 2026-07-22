module RivetCms
  class Organization < ApplicationRecord
    # Organization has no prefix id, so prefixed_ids does not patch its
    # has_many finders; extend explicitly so find accepts prefixed ids.
    PREFIXED_FINDERS = PrefixedIds::Finder::ClassMethods

    has_many :content_types, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :components, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :categories, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :media_assets, dependent: :destroy, extend: PREFIXED_FINDERS
    has_many :api_tokens, dependent: :destroy, extend: PREFIXED_FINDERS

    validates :name, presence: true
    validates :domain, presence: true, uniqueness: true
    validates :subdomain, uniqueness: true, allow_blank: true
  end
end
