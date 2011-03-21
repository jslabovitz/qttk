module Color
  
  class GrayScale
  
    def self.from_density(d)
      from_fraction(1 - d)
    end
    
    def density
      1 - @g
    end
  
    def log_density
      Math::log10(density * 100)
    end
  
    def to_qtr(channel=7)
      Color::QTR.new(channel, @g)
    end
    
    def hash
      @g.hash
    end
    
    def eql?(other)
      @g == other.g
    end
    
  end
  
end