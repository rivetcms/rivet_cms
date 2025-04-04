module RivetCms
  module BrandColorHelper
    # Generate CSS for brand colors based on the primary color
    def brand_color_css
      base_color = "#ff7043"
      
      # Generate CSS variables for all the shades
      <<~CSS
        <style id="brand-colors">
          :root {
            --color-brand-50: #{lighten_color(base_color, 0.85)};
            --color-brand-100: #{lighten_color(base_color, 0.7)};
            --color-brand-200: #{lighten_color(base_color, 0.55)};
            --color-brand-300: #{lighten_color(base_color, 0.4)};
            --color-brand-400: #{lighten_color(base_color, 0.2)};
            --color-brand-500: #{lighten_color(base_color, 0.1)};
            --color-brand-600: #{base_color};
            --color-brand-700: #{darken_color(base_color, 0.1)};
            --color-brand-800: #{darken_color(base_color, 0.2)};
            --color-brand-900: #{darken_color(base_color, 0.3)};
            --color-brand-950: #{darken_color(base_color, 0.4)};
          }
        </style>
      CSS
    end
    
    private
    
    # Simple color manipulation helpers
    def lighten_color(hex_color, amount)
      manipulate_color(hex_color) do |r, g, b|
        [
          [(r + (255 - r) * amount).round, 255].min,
          [(g + (255 - g) * amount).round, 255].min,
          [(b + (255 - b) * amount).round, 255].min
        ]
      end
    end
    
    def darken_color(hex_color, amount)
      manipulate_color(hex_color) do |r, g, b|
        [
          [(r * (1 - amount)).round, 0].max,
          [(g * (1 - amount)).round, 0].max,
          [(b * (1 - amount)).round, 0].max
        ]
      end
    end
    
    def manipulate_color(hex_color)
      hex_color = hex_color.gsub('#', '')
      
      # Convert to RGB
      if hex_color.length == 3
        r = hex_color[0].to_i(16) * 17
        g = hex_color[1].to_i(16) * 17
        b = hex_color[2].to_i(16) * 17
      else
        r = hex_color[0..1].to_i(16)
        g = hex_color[2..3].to_i(16)
        b = hex_color[4..5].to_i(16)
      end
      
      # Apply transformation
      new_r, new_g, new_b = yield(r, g, b)
      
      # Convert back to hex
      "#%02x%02x%02x" % [new_r, new_g, new_b]
    end
  end
end 