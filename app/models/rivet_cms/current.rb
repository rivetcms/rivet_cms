module RivetCms
  class Current < ActiveSupport::CurrentAttributes
    attribute :organization
    attribute :user
  end
end
