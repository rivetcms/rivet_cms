module RivetCms
  module FlashHelper
    def flash_class_for(type)
      case type.to_sym
      when :notice, :success
        "bg-green-50"
      when :error, :alert
        "bg-red-50"
      when :warning
        "bg-yellow-50"
      else
        "bg-gray-50"
      end
    end

    def flash_icon_for(type)
      case type.to_sym
      when :notice, :success
        content_tag(:svg, class: "h-5 w-5 text-green-400", viewBox: "0 0 20 20", fill: "currentColor") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z", clip_rule: "evenodd")
        end
      when :error, :alert
        content_tag(:svg, class: "h-5 w-5 text-red-400", viewBox: "0 0 20 20", fill: "currentColor") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z", clip_rule: "evenodd")
        end
      when :warning
        content_tag(:svg, class: "h-5 w-5 text-yellow-400", viewBox: "0 0 20 20", fill: "currentColor") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z", clip_rule: "evenodd")
        end
      else
        content_tag(:svg, class: "h-5 w-5 text-gray-400", viewBox: "0 0 20 20", fill: "currentColor") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z", clip_rule: "evenodd")
        end
      end
    end
  end
end