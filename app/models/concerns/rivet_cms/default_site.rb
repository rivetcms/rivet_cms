module RivetCms
  module DefaultSite
    extend ActiveSupport::Concern
    included do
      before_validation :set_default_site_id, on: :create
    end

    private
    
    def set_default_site_id
      self.site_id ||= 0
    end
  end
end