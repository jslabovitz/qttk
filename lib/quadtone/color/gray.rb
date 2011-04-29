module Color
  
  class Gray < Base
        
    def self.from_cgats(gray)
      new(gray / 100.0)
    end
    
    def self.cgats_fields
      %w{GRAY}
    end
    
    def self.component_names
      [:value]
    end
    
    def initialize(value)
      super([value])
    end
    
    def value
      @components[0]
    end
    
    def to_cgats
      [value * 100]
    end
    
    def html
      '#' + (("%02x" % (255 - (value * 255))) * 3)
    end

    def inspect
      "<Gray: %.2f>" % (value * 100)
    end

  end
  
end