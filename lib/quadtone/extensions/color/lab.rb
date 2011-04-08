module Color
  
  class Lab
    
    attr_accessor :l
    attr_accessor :a
    attr_accessor :b
    
    def initialize(l, a, b)
      @l, @a, @b = l.to_f, a.to_f, b.to_f
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
    
    def to_lch
      # http://www.brucelindbloom.com/Eqn_Lab_to_LCH.html
      c = Math::sqrt((@a * @a) + (@b * @b))
      h = Math::atan2(@b, @a) * (180 / Math::PI)
      h += 360 if h < 0
      h -= 360 if h >= 360
      LCH.new(@l, c, h)
    end
    
    def delta(other)
      (@l - other.l).abs
    end
    
    def <=>(other)
      @l <=> other.l
    end
        
    def hash
      [@l, @a, @b].hash
    end
    
    def eql?(other)
      [@l, @a, @b] == [other.l, other.a, other.b]
    end
    
    def inspect
      "Lab [%.2f, a=%.2f, b=%.2f]" % [@l, @a, @b]
    end
    
  end
  
end