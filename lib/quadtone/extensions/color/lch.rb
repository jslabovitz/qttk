module Color
  
  class LCH
    
    attr_accessor :l
    attr_accessor :c
    attr_accessor :h
    
    def initialize(l, c, h)
      @l, @c, @h = l.to_f, c.to_f, h.to_f
    end
    
    def density
      (100 - @l) / 100.0
    end
    
    def log_density
      Math::log10(density)
    end
    
    def to_grayscale
      GrayScale.new(@l)
    end
    
    def delta(other)
      (@l - other.l).abs
    end
    
    def <=>(other)
      @l <=> other.l
    end
        
    def hash
      [@l, @c, @h].hash
    end
    
    def eql?(other)
      [@l, @c, @h] == [other.l, other.c, other.h]
    end
    
    def inspect
      "Lab [%.2f, C=%.2f, H=%.2f]" % [@l, @c, @h]
    end
    
  end
  
end