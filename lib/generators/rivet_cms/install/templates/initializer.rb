# RivetCms delegates authentication to your application — it ships no login of
# its own. Wire your auth (Devise, Rails 8 authentication generator, custom
# sessions) into the lambdas below. Without configuration the admin UI is OPEN
# in development/test and BLOCKED (403) in production.
#
# RivetCms.configure do |config|
#   # Engine controllers inherit from this class, making your auth filters and
#   # helpers available. Point it at a slim controller if your
#   # ApplicationController carries many before_actions.
#   config.parent_controller = "ApplicationController"
#
#   # Return truthy to allow the request, falsy to deny it. On denial RivetCms
#   # redirects browsers to login_path (or 403s) and returns 401 to the SPA — so
#   # a boolean check is enough and fails CLOSED. (You may also render/redirect
#   # yourself for custom handling; the engine respects a response you've made.)
#   config.authenticate = ->(controller) { controller.send(:user_signed_in?) } # Devise example
#   # Devise's authenticate_user! also works (returns the user, redirects on failure):
#   # config.authenticate = ->(controller) { controller.send(:authenticate_user!) }
#
#   # The signed-in host user (or nil). Used for revision authorship and the
#   # header identity display.
#   config.current_user = ->(controller) { controller.send(:current_user) }
#
#   # How to display a user. Defaults try full_name/name/display_name/email.
#   # config.user_name  = ->(user) { user.full_name }
#   # config.user_email = ->(user) { user.email }
#
#   # Where the admin frontend sends the browser when a session expires (401).
#   config.login_path = "/users/sign_in"
#
#   # Renders a Log out button in the admin header, submitted as a real form
#   # (with _method) so DELETE routes work. nil hides the button.
#   config.logout_path = "/users/sign_out"
#   config.logout_method = "delete"
#
#   # Media/upload settings:
#   # config.max_upload_size = 100 * 1024 * 1024
#   # config.media_host = "https://cms.example.com"
#   #
#   # MIME types the media library accepts (checked against the sniffed type).
#   # Defaults to common image/video/audio/document types; SVG is excluded
#   # because scripted SVGs can carry XSS. Set to nil to allow anything.
#   # config.allowed_media_types += %w[image/svg+xml]
#
#   # Delivery API: false (default) requires an API token; true allows anonymous
#   # reads of published content. Preview (draft) reads always need a token.
#   # config.public_api = false
# end
