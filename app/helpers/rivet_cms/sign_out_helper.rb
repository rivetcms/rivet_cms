module RivetCms
  module SignOutHelper
    # Returns the sign-out path for the application.
    # Uses RivetCmsAuth’s auth_sign_out_path if available, otherwise falls back to the configured path or root.
    def rivet_sign_out_path
      config = RivetCms.configuration
      return config.sign_out_path.call if config.sign_out_path.respond_to?(:call)
      config.sign_out_path || "/"
    end
  end
end
