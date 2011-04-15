module Color
  
  class Gray
    
    attr_accessor :value
    
    def self.from_cgats(gray)
      new(gray / 100.0)
    end
    
    def self.components
      [:value]
    end
    
    def self.average(colors)
      errors = []
      if true
        avg_components = components.map do |comp|
          median, mad = colors.map(&comp).median, colors.map(&comp).mad
          errors << mad / median
          median
        end
      else
        avg_components = components.map do |comp|
          mean, stdev = colors.map(&comp).mean_stdev
          errors << stdev / mean
          mean
        end
      end
      [new(*avg_components), errors.max]
    end
        
    def initialize(value)
      @value = value
    end
    
    def to_cgats
      [@value * 100]
    end
    
    def to_gray
      Gray.new(@value)
    end
    
    def html
      '#' + (("%02x" % (255 - (@value * 255))) * 3)
    end

    def hash
      @value.hash
    end
    
    def eql?(other)
      @value == other.value
    end
    
    def <=>(other)
      @value <=> other.value
    end
    
    def inspect
      "<Gray: %.2f>" % (@value * 100)
    end
  end
  
end