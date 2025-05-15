module RivetCms
  class ApplicationController < ActionController::Base
    include RivetCms.configuration.auth_class

    before_action :authenticate_user!

    before_action :set_preline_path

    private

    def authenticate_user!
      redirect_to sign_in_path unless user_signed_in?
    end

    def set_preline_path
      prepend_view_path RivetCms::Engine.root.join("app/views/preline")
    end
  end
end
