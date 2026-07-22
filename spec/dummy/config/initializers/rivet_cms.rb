# Live example of RivetCms auth delegation, wired to the dummy app's session
# auth (SessionsController + /login). Development requires sign-in, just like
# a real host. Test is excluded: the suite configures lambdas per-example.
# For the full annotated template, run: rails g rivet_cms:install
unless Rails.env.test?
  RivetCms.configure do |config|
    config.parent_controller = "ApplicationController"

    config.authenticate = ->(controller) { controller.user_signed_in? }
    config.current_user = ->(controller) { controller.current_user }

    config.login_path = "/login"
    config.logout_path = "/logout"
    config.logout_method = "delete"
  end
end
