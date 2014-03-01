module Color
  
  class Lab < Base
    
    include Math
    
    def self.component_names
      [:value, :a, :b]
    end
    
    def self.cgats_fields
      %w{LAB_L LAB_A LAB_B}
    end
    
    def self.from_cgats(set)
      l, a, b = set.values_at(*cgats_fields)
      new((100 - l) / 100.0, a, b)
    end
    
    def initialize(value, a=0, b=0)
      super([value, a.to_f, b.to_f])
    end
        
    def value
      @components[0]
    end

    def l
      100 - (@components[0] * 100)
    end
    
    def a
      @components[1]
    end
    
    def b
      @components[2]
    end
    
    def chroma
      # http://www.brucelindbloom.com/Eqn_Lab_to_LCH.html
      sqrt((a * a) + (b * b))
    end
    
    def hue
      # http://www.brucelindbloom.com/Eqn_Lab_to_LCH.html
      if a == 0 && b == 0
        0
      else
        rad2deg(atan2(b, a)) % 360
      end
    end
    
    def delta_e(other, method=:cmclc)
      # http://en.wikipedia.org/wiki/Color_difference
      # http://www.brucelindbloom.com/iPhone/ColorDiff.html
      l1, a1, b1 = self.l, self.a, self.b
      l2, a2, b2 = other.l, other.a, other.b
      c1, c2 = self.chroma, other.chroma
      h1, h2 = self.hue, other.hue
      dl = l2 - l1
      da = a1 - a2
      db = b1 - b2
      dc = c1 - c2
      dh2 = da**2 + db**2 - dc**2
      return Float::NAN if dh2 < 0
      dh = sqrt(dh2)
      case method
      when :density
        dl.abs
      when :cie76
        sqrt(dl**2 + da**2 + db**2)
      when :cie94
        kl, k1, k2 = 1, 0.045, 0.015
        sqrt(
          (dl / kl)**2 +
          (dc / (1 + k1*c1))**2 +
          (dh / (1 + k2*c2)**2)
        )
      when :cmclc
        l, c = 2, 1
        sl = (l1 < 16) ? 
          0.511 : 
          0.040975 * l1 / (1 + 0.01765 * l1)
        sc = 0.0638 * c1 / (1 + 0.0131 * c1) + 0.638
        f = sqrt(
          (c1 ** 4) / ((c1 ** 4) + 1900)
        )
        t = (h1 >= 164 && h1 <= 345) ?
          0.56 + (0.2 * cos(deg2rad(h1 + 168))).abs :
          0.36 + (0.4 * cos(deg2rad(h1 + 35))).abs
        sh = sc * ((f * t) + 1 - f)
        sqrt(
          (dl / (l * sl)) ** 2 +
          (dc / (c * sc)) ** 2 +
          (dh / sh) ** 2
        )
      else
        raise "Unknown deltaE method: #{method.inspect}"
      end
    end
    
    REF_X =  95.047     # Observer= 2°, Illuminant= D65
    REF_Y = 100.000
    REF_Z = 108.883
    
    def to_xyz
      # after http://www.easyrgb.com/index.php?X=MATH&H=08#text8
      
      y = (l + 16) / 116
      x = a / 500 + y
      z = y - b / 200
      
      x0, y0, z0 = [x, y, z].map do |n|
        if (n3 = n**3) > 0.008856
          n = n3
        else
          n = (n - 16 / 116) / 7.787
        end
      end
      
      x0 = (x * REF_X) / 100
      y0 = (y * REF_Y) / 100
      z0 = (z * REF_Z) / 100
      
      Color::XYZ.new(x0, y0, z0)
    end
    
    def to_rgb
      to_xyz.to_rgb
    end
    
    def inspect
      "<Lab: L=%3.2f, a=%.2f, b=%.2f>" % [l, a, b]
    end
    
  end
  
end

if $0 == __FILE__
  
  pairs = [
    [Color::Lab.from_lab(50,0,0), Color::Lab.from_lab(50,0,0)],
    [Color::Lab.from_lab(50,0,0), Color::Lab.from_lab(51,0,0)],
    [Color::Lab.from_lab(50,0,0), Color::Lab.from_lab(50,0,1)],
    [Color::Lab.from_lab(50,0,0), Color::Lab.from_lab(50,1,0)],
    [Color::Lab.from_lab(50,0,0), Color::Lab.from_lab(50,1,1)],
  ]

  pairs.each do |pair|
    l1, l2 = *pair
    puts "#{l1.inspect} ~ #{l2.inspect}"
    [:density, :cie76, :cie94, :cmclc].each do |method|
      puts "\t" + "#{method}: %.4f" % l1.delta_e(l2, method)
    end
  end
  
end