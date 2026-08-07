module RivetCms
  # Immutable description of one authorization check, passed to RivetCms.can.
  # Checks run in two phases: first with record nil, before anything loads
  # ("is this action available to the user at all", also drives the sidebar),
  # then again with record set to the loaded entry, content type, field,
  # component, media asset, or API token. Fields may be ADDED in minor
  # releases; policies should read only the fields they need and treat
  # unknown action/resource symbols as deny, since the vocabulary grows.
  AccessCheck = Struct.new(:user, :action, :resource, :organization, :record, keyword_init: true)

  class AccessDenied < StandardError; end
end
