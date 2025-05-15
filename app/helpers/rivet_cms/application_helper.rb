module RivetCms
  module ApplicationHelper
    include RivetCms::BrandColorHelper
    include RivetCms::SignOutHelper
    include RivetCms::FlashHelper

    def flash_class_for(type)
      case type.to_sym
      when :alert, :error
        "bg-red-50 dark:bg-red-900/20"
      when :notice, :success
        "bg-green-50 dark:bg-green-900/20"
      when :info
        "bg-blue-50 dark:bg-blue-900/20"
      when :warning
        "bg-yellow-50 dark:bg-yellow-900/20"
      else
        "bg-gray-50 dark:bg-gray-900/20"
      end
    end

    def flash_border_class_for(type)
      case type.to_sym
      when :alert, :error
        "border-red-400 dark:border-red-700"
      when :notice, :success
        "border-green-400 dark:border-green-700"
      when :info
        "border-blue-400 dark:border-blue-700"
      when :warning
        "border-yellow-400 dark:border-yellow-700"
      else
        "border-gray-300 dark:border-gray-700"
      end
    end

    def flash_accent_class_for(type)
      case type.to_sym
      when :alert, :error
        "bg-red-500"
      when :notice, :success
        "bg-green-500"
      when :info
        "bg-blue-500"
      when :warning
        "bg-yellow-500"
      else
        "bg-gray-500"
      end
    end

    def flash_icon_for(type)
      # ... existing code ...
    end
  end
end
