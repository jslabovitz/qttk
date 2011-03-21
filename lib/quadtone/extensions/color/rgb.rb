module Color
  
  class RGB
  
    def to_qtr
      Color::QTR.from_rgb(@r, @g, @b)
    end
    
    def hash
      [@r, @g, @b].hash
    end

    def eql?(other)
      [@r, @g, @b] == [other.r, other.g, other.b]
    end
    
  end
    
end