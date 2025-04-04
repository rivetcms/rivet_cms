require "rivet_cms/version"
require "rivet_cms/routes"
require "rivet_cms/engine"

module RivetCms
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configuration=(config)
      @configuration = config
    end
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    validate_user_class(configuration.user_class)
  end

  class Configuration
    attr_accessor :user_class, :image_variants, :current_user_method, 
                  :prefixed_ids_length, :prefixed_ids_salt, :prefixed_ids_alphabet,
                  :sign_in_path, :sign_out_path, :auth_class

    def initialize
      @user_class = "RivetCms::User"
      @image_variants = {
        thumbnail: { width: 100, height: 100, resize: "fit" },
        medium: { width: 800, height: 600, resize: "limit" }
      }
      @current_user_method = "current_user"
      @prefixed_ids_length = 32
      @prefixed_ids_salt = "rivet-cms-#{Rails.env}"
      @prefixed_ids_alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
      @auth_class = RivetCms::Authentication
      @sign_in_path = nil
      @sign_out_path = nil
    end
  end
end
