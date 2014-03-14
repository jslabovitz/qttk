module Color

  class XYZ < Base

    # Observer= 2°, Illuminant= D65
    def self.standard_reference
      @@reference ||= new([95.047, 100.000, 108.883])
    end

    def self.component_names
      [:x, :y, :z]
    end

    def self.cgats_fields
      %w{XYZ_X XYZ_Y XYZ_Z}
    end

    def x
      @components[0]
    end

    def y
      @components[1]
    end

    def z
      @components[2]
    end

    def to_lab
      # http://www.easyrgb.com/index.php?X=MATH&H=07#text7

      ref = self.class.standard_reference

      x = self.x / ref.x
      y = self.y / ref.y
      z = self.z / ref.z

      x, y, z = [x, y, z].map do |n|
        if n > 0.008856
          n ** (1.0 / 3)
        else
          (7.787 * n) + (16 / 116)
        end
      end

      l = (116 * y) - 16
      a = 500 * (x - y)
      b = 200 * (y - z)

      Color::Lab.new([l, a, b])
    end

    def to_rgb
      rgb = [
        (x *  3.2406) + (y * -1.5372) + (z * -0.4986),
        (x * -0.9689) + (y *  1.8758) + (z *  0.0415),
        (x *  0.0557) + (y * -0.2040) + (z *  1.0570),
      ]
      rgb = rgb.map do |n|
        if n > 0.0031308
          1.055 * (n ** (1 / 2.4)) - 0.055
        else
          12.92 * rgb[0]
        end
      end
      Color::RGB.new(rgb)
    end

    def to_cgats
      {
        'XYZ_X' => x,
        'XYZ_Y' => y,
        'XYZ_Z' => z,
      }
    end

  end

end