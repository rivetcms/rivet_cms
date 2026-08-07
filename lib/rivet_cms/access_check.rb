module RivetCms
  # Immutable description of one authorization check, passed to RivetCms.can.
  # Fields may be ADDED in minor releases (record is reserved for future
  # finer-grained checks and is currently always nil); policies should read
  # only the fields they need and treat unknown action/resource symbols as
  # deny, since the vocabulary also grows over time.
  AccessCheck = Struct.new(:user, :action, :resource, :organization, :record, keyword_init: true)

  class AccessDenied < StandardError; end
end
