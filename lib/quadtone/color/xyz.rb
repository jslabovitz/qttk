module Color
  
  class XYZ < Base
    
    include Math
    
    def self.component_names
      [:x, :y, :z]
    end
    
    def self.cgats_fields
      %w{XYZ_X XYZ_Y XYZ_Z}
    end
    
    def self.from_cgats(set)
      x, y, z = set.values_at(*cgats_fields)
      new(x / 100.0, y / 100.0, z / 100.0)
    end
    
    def initialize(x, y, z)
      super([x.to_f, y.to_f, z.to_f])
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
    
    def to_rgb
      rgb = [
        (x *  3.2406) + (y * -1.5372) + (z * -0.4986),
        (x * -0.9689) + (y *  1.8758) + (z *  0.0415),
        (x *  0.0557) + (y * -0.2040) + (z *  1.0570),
      ].map do |n|
        if n > 0.0031308
          1.055 * (n ** (1 / 2.4)) - 0.055
        else
          12.92 * r
        end
      end
      Color::RGB.new(*rgb)
    end
    
    def to_cgats
      {
        'XYZ_X' => x * 100,
        'XYZ_Y' => y * 100,
        'XYZ_Z' => z * 100,
      }
    end
    
    def inspect
      "<XYZ: X=%3d%%, Y=%3d%%, Z=%3d%%>" % [x, y, z].map { |n| n * 100 }
    end
    
  end
  
end