module Color
  
  class Gray < Base
        
    def self.component_names
      [:K]
    end
    
    def self.cgats_fields
      %w{GRAY_K}
    end
    
    def self.from_cgats(set)
      value = set.values_at(*cgats_fields).first
      new(value / 100.0)
    end
    
    def initialize(value)
      super([value])
    end
    
    def value
      @components[0]
    end
    
    def channel_name
      component_names.first
    end
    
    def to_cgats
      {
        'GRAY_K' => value * 100,
      }
    end
    
    def to_rgb
      Color::RGB.new(1 - value, 1 - value, 1 - value)
    end
    
    def to_lab
      Color::Lab.new(1 - value, 0, 0)
    end
    
    def to_xyz
      to_lab.to_xyz
    end
    
    def to_pixel
      Magick::Pixel.new(*to_rgb.to_a.map { |n| n * Magick::QuantumRange })
    end
    
    def inspect
      "<Gray: %3d%%>" % (value * 100)
    end

  end
  
end