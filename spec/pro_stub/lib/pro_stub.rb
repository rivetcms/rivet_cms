# A stand-in for the Pro gem: a second Rails engine that attaches to every CE
# extension seam. It boots like a real gem (required from the dummy app), so
# its initializer and autoload paths behave exactly as a Pro engine's would.
#
# Seam registrations live in ProStub.install! instead of the initializer only
# because boot-time registration would leak a nav item and hook subscriptions
# into every other example; install! runs inside an example and the suite's
# snapshot/restore support puts the registries back afterward. A real gem
# makes these same calls from its initializer.
require "pro_stub/engine"

module ProStub
  class << self
    # What the hook subscriptions saw, for specs to assert against
    def received
      @received ||= []
    end

    def pruned
      @pruned ||= []
    end

    def audits
      @audits ||= []
    end

    def install!
      RivetCms.register_nav :pro_panel,
        label: "Pro Panel",
        section: "Pro",
        requires: [ :read, :pro_panel ],
        path: -> { pro_stub_panel_path },
        position: 90

      RivetCms.register_admin_script "rivet_cms_pro"
      RivetCms.register_admin_stylesheet "rivet_cms_pro"

      RivetCms.on(:publish, key: :pro_stub_publish) { |revision| ProStub.received << revision }
      RivetCms.on(:prune, key: :pro_stub_prune) { |revision| ProStub.pruned << revision.id }
      RivetCms.on(:audit, key: :pro_stub_audit) { |event| ProStub.audits << event }
    end
  end
end
