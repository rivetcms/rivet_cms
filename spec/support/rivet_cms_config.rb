# Saves and restores RivetCms auth config around every example so specs can
# reconfigure freely. parent_controller is restored defensively only — the
# engine controller class is already loaded, so changing it mid-suite has no effect.
RIVET_AUTH_CONFIG_KEYS = %i[can revision_retention
  parent_controller authenticate current_user user_name user_email
  login_path logout_path logout_method public_api
].freeze

RSpec.configure do |config|
  # The suite runs in host-auth mode with a permissive lambda; built-in auth
  # specs opt back in with RivetCms.authenticate = RivetCms::DEFAULT_AUTHENTICATE
  config.before(:each) do
    RivetCms.authenticate = ->(_controller) { true }
    RivetCms.current_user = ->(_controller) { nil }
  end

  # Hook subscriptions are process-global: snapshot and restore them so a
  # spec's handler cannot fire during every later example.
  config.around(:each) do |example|
    snapshot = RivetCms::Hooks.snapshot
    example.run
  ensure
    RivetCms::Hooks.restore(snapshot)
  end

  config.around(:each) do |example|
    saved = RIVET_AUTH_CONFIG_KEYS.index_with { |key| RivetCms.public_send(key) }
    example.run
  ensure
    saved.each { |key, value| RivetCms.public_send("#{key}=", value) }
    RivetCms::Current.reset
  end

  # Nav items and admin asset lists are process-global like hooks
  config.around(:each) do |example|
    nav = RivetCms::Navigation.snapshot
    scripts = RivetCms.admin_scripts.dup
    stylesheets = RivetCms.admin_stylesheets.dup
    example.run
  ensure
    RivetCms::Navigation.restore(nav)
    RivetCms.admin_scripts = scripts
    RivetCms.admin_stylesheets = stylesheets
  end
end
