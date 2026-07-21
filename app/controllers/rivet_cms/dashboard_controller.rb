module RivetCms
  class DashboardController < ApplicationController
    def show
      render inertia: "Dashboard/Show"
    end
  end
end
