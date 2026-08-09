# By default the dummy runs like a fresh install: built-in auth, first visit
# creates the owner. RIVET_HOST_AUTH=1 bin/dev switches to the host-auth
# delegation demo instead (the dummy's own SessionsController + /host/login),
# the wiring a real host with existing auth would use. Test is excluded: the
# suite configures lambdas per-example. Full template: rails g rivet_cms:install
if !Rails.env.test? && ENV["RIVET_HOST_AUTH"].present?
  RivetCms.configure do |config|
    config.parent_controller = "ApplicationController"

    config.authenticate = ->(controller) { controller.user_signed_in? }
    config.current_user = ->(controller) { controller.current_user }

    config.login_path = "/host/login"
    config.logout_path = "/host/logout"
    config.logout_method = "delete"
  end
end
