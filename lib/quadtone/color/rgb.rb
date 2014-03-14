module Color

  class RGB < Base

    def self.component_names
      [:r, :g, :b]
    end

    def self.cgats_fields
      %w{RGB_R RGB_G RGB_B}
    end

    def self.from_cgats(set)
      new(*set.values_at(*cgats_fields).map { |n| n / 100.0 })
    end

    def r
      @components[0]
    end

    def g
      @components[1]
    end

    def b
      @components[2]
    end

    def to_cgats
      {
        'RGB_R' => r * 100,
        'RGB_G' => g * 100,
        'RGB_B' => b * 100,
      }
    end

    def to_xyz
      # after http://www.easyrgb.com/index.php?X=MATH&H=02#text2

      r0, g0, b0 = [r, g, b].map do |n|
        if n > 0.04045
          ((n + 0.055) / 1.055) ** 2.4
        else
          n / 12.92
        end
      end

      r0 *= 100
      g0 *= 100
      b0 *= 100

      # Observer. = 2°, Illuminant = D65

      x = (r0 * 0.4124) + (g0 * 0.3576) + (b0 * 0.1805)
      y = (r0 * 0.2126) + (g0 * 0.7152) + (b0 * 0.0722)
      z = (r0 * 0.0193) + (g0 * 0.1192) + (b0 * 0.9505)

      Color::XYZ.new([x, y, z])
    end

    def to_a
      [r, g, b]
    end

    def to_pixel
      Magick::Pixel.new(*to_a.map { |n| n * Magick::QuantumRange })
    end

  end

end