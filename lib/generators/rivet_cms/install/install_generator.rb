module RivetCms
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates the RivetCms initializer with the auth delegation template"

      def copy_initializer
        copy_file "initializer.rb", "config/initializers/rivet_cms.rb"
      end
    end
  end
end
