module RivetCms
  class Organization < ApplicationRecord
    has_many :users, dependent: :destroy
    has_many :content_types, dependent: :destroy
    has_many :categories, dependent: :destroy
    has_many :components, dependent: :destroy

    validates :name, presence: true
    validates :domain, presence: true, uniqueness: true
    validates :subdomain, uniqueness: true, allow_blank: true
  end
end
