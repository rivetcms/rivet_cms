module RivetCms
  # Base for the built-in auth surfaces (login, first-run setup, invitation
  # links). Reachable without a session by definition; hard 404 when the host
  # brought its own authentication so they add no surface area in that mode.
  class AuthController < ApplicationController
    skip_before_action :authenticate_rivet_user
    skip_before_action :set_rivet_current_user
    before_action :ensure_builtin_mode

    private

    def ensure_builtin_mode
      head :not_found unless RivetCms.builtin_auth?
    end

    def sign_in(user)
      reset_session # session fixation
      session[:rivet_cms_user_id] = user.id
      # Binding the session to the password salt revokes every session the
      # moment the password changes
      session[:rivet_cms_password_salt] = user.password_salt
    end

    def users
      User.where(organization: Current.organization)
    end
  end
end
