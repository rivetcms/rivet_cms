module ProStub
  class Engine < ::Rails::Engine
    # Admin pages live inside the CMS route set so they share its layout,
    # authentication, and helpers; this is the pattern a real extension uses.
    initializer "pro_stub.admin_routes" do
      RivetCms::Engine.routes.append do
        # Leading slash: the CMS routes are namespace-isolated, so a bare
        # controller path would resolve inside RivetCms::
        get "/pro", to: "/pro_stub/panel#index", as: :pro_stub_panel
      end
    end
  end
end
