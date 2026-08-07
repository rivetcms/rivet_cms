module RivetCms
  module ApplicationHelper
    # Fails open on the page, closed on the asset: a registered extension
    # bundle that cannot be resolved is logged and skipped instead of 500ing
    # every admin page. Matches the can? posture of degrading rather than
    # taking the whole admin down over an initializer typo.
    def admin_extension_tag(kind, name)
      case kind
      when :script then javascript_include_tag(name, type: "module", defer: true)
      when :stylesheet then stylesheet_link_tag(name, media: "all")
      end
    rescue StandardError => error
      Rails.logger&.error("[RivetCms] admin #{kind} #{name.inspect} could not be rendered (skipping): #{error.class}: #{error.message}")
      nil
    end
  end
end
