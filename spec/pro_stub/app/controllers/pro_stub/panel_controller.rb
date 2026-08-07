module ProStub
  class PanelController < RivetCms::ApplicationController
    def index
      authorize! :read, :pro_panel
      render inertia: "ProStub/Panel", props: { message: "hello from the pro stub" }
    end
  end
end
