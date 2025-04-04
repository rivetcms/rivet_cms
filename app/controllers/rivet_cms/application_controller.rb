module RivetCms
  class ApplicationController < ActionController::Base
    include RivetCms.configuration.auth_class

    before_action :authenticate_user!

    private

    def authenticate_user!
      redirect_to sign_in_path unless user_signed_in?
    end
  end
end
