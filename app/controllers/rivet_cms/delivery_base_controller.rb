module RivetCms
  # Deliberately independent of the host-configured parent_controller: the
  # delivery API is token-gated JSON, so host auth filters, layouts, and
  # rescue_from handlers must never apply to it. The organization comes from
  # the token, or from the request host in public mode.
  class DeliveryBaseController < ActionController::Base
    include ResolvesOrganization

    # TODO: the delivery API is GET-only, so the CSRF protection inherited
    # from ActionController::Base never runs. If a write endpoint is ever
    # added here, disable it for this base (protect_from_forgery with:
    # :null_session): API clients authenticate with bearer tokens, not
    # session cookies, and would otherwise be rejected with 422s.
  end
end
