module RivetCms
  # Deliberately independent of the host-configured parent_controller: the
  # delivery API is token-gated JSON, so host auth filters, layouts, and
  # rescue_from handlers must never apply to it. The organization comes from
  # the token, or from the request host in public mode.
  class DeliveryBaseController < ActionController::Base
    include ResolvesOrganization
  end
end
