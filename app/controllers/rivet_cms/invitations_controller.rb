module RivetCms
  # Set-password links: signed, expiring, invalidated the moment a password
  # is set (the token embeds the password salt). No mailers involved; the
  # admin copies the link and delivers it however they like.
  class InvitationsController < AuthController
    before_action :set_user_from_token

    def show
      render inertia: "Auth/SetPassword", props: { name: @user.name, submit_path: invitation_path(params[:token]) }
    end

    def update
      if params[:password].blank?
        # An empty string is ignored by has_secure_password: update would
        # "succeed" without setting anything and sign in a pending user
        return redirect_to invitation_path(params[:token]), inertia: { errors: { password: [ "can't be blank" ] } }
      end

      if @user.update(password: params[:password])
        sign_in(@user)
        redirect_to root_path, notice: "You're in. Welcome to RivetCMS"
      else
        redirect_to invitation_path(params[:token]), inertia: { errors: @user.errors }
      end
    end

    private

    def set_user_from_token
      @user = User.find_by_token_for(:password_setup, params[:token])
      return if @user&.active? && @user.organization == Current.organization

      redirect_to login_path, alert: "That link is no longer valid. Ask an admin for a new one."
    end
  end
end
