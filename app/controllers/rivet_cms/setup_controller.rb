module RivetCms
  # First-run screen: with no users at all, the first visit creates the owner
  # account. Gone the moment one user exists; never a registration form.
  #
  # Outside development/test a fresh deployment cannot be claimed by whoever
  # finds it first: setup demands a code that is written to the server log
  # (or configured via RivetCms.setup_code), so claiming requires server
  # access. The Jenkins initial-password pattern.
  class SetupController < AuthController
    before_action :ensure_first_run

    def new
      log_setup_code
      render inertia: "Auth/Setup", props: { submit_path: setup_path, requires_code: RivetCms.setup_code_required? }
    end

    def create
      unless setup_code_valid?
        return redirect_to setup_path,
                           inertia: { errors: { base: [ "That setup code is not right. It is printed in the server log." ] } }
      end
      if params[:password].blank?
        # has_secure_password ignores an empty string entirely, which would
        # otherwise create a passwordless owner and sign them in
        return redirect_to setup_path, inertia: { errors: { password: [ "can't be blank" ] } }
      end

      user = users.new(user_params)

      if user.save
        sign_in(user)
        redirect_to root_path, notice: "Welcome to RivetCMS"
      else
        redirect_to setup_path, inertia: { errors: user.errors }
      end
    end

    private

    def ensure_first_run
      redirect_to login_path if users.any?
    end

    def setup_code_valid?
      return true unless RivetCms.setup_code_required?

      ActiveSupport::SecurityUtils.secure_compare(params[:setup_code].to_s, RivetCms.setup_code)
    end

    def log_setup_code
      return unless RivetCms.setup_code_required?

      Rails.logger&.info("[RivetCms] First-run setup code: #{RivetCms.setup_code}")
    end

    def user_params
      params.permit(:name, :email, :password)
    end
  end
end
