# Saves and restores RivetCms auth config around every example so specs can
# reconfigure freely. parent_controller is restored defensively only — the
# engine controller class is already loaded, so changing it mid-suite has no effect.
RIVET_AUTH_CONFIG_KEYS = %i[
  parent_controller authenticate current_user user_name user_email
  login_path logout_path logout_method public_api
].freeze

RSpec.configure do |config|
  config.around(:each) do |example|
    saved = RIVET_AUTH_CONFIG_KEYS.index_with { |key| RivetCms.public_send(key) }
    example.run
  ensure
    saved.each { |key, value| RivetCms.public_send("#{key}=", value) }
    RivetCms::Current.reset
  end
end
