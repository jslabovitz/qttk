module Color
  
  class Lab < Base
    
    include Math
    
    def self.from_lab(l, a, b)
      new((100 - l) / 100.0, a, b)
    end
    
    def self.cgats_fields
      %w{LAB_L LAB_A LAB_B}
    end
    
    def self.from_cgats(l, a, b)
      from_lab(l, a, b)
    end
    
    def self.component_names
      [:value, :a, :b]
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
    
    def to_xyz
      # after http://www.easyrgb.com/index.php?X=MATH&H=08#text8
      
      y = (l + 16) / 116
      x = a / 500 + y
      z = y - b / 200

      if y**3 > 0.008856
        y = y**3
      else
        y = (y - 16 / 116) / 7.787
      end
      
      if x**3 > 0.008856
        x = x**3
      else
        x = (x - 16 / 116) / 7.787
      end
      
      if z**3 > 0.008856
        z = z**3
      else
        z = (z - 16 / 116) / 7.787
      end
      
      ref_x =  95.047     # Observer= 2°, Illuminant= D65
      ref_y = 100.000
      ref_z = 108.883
      
      x *= ref_x
      y *= ref_y
      z *= ref_z
      
      [x, y, z]
    end
    
    def to_rgb
      x, y, z = to_xyz
      
      x /= 100.0        # X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
      y /= 100.0        # Y from 0 to 100.000
      z /= 100.0        # Z from 0 to 108.883

      r = x *  3.2406 + y * -1.5372 + z * -0.4986
      g = x * -0.9689 + y *  1.8758 + z *  0.0415
      b = x *  0.0557 + y * -0.2040 + z *  1.0570

      if r > 0.0031308
        r = 1.055 * (r ** (1 / 2.4)) - 0.055
      else
        r = 12.92 * r
      end
      
      if g > 0.0031308
        g = 1.055 * (g ** (1 / 2.4)) - 0.055
      else
        g = 12.92 * g
      end
      
      if b > 0.0031308
        b = 1.055 * (b ** (1 / 2.4)) - 0.055
      else
        b = 12.92 * b
      end

      r = (r * 255).to_i
      g = (g * 255).to_i
      b = (b * 255).to_i
      
      [r, g, b]
    end
    
    def inspect
      "<Lab: L=%.2f, a=%.2f, b=%.2f>" % [l, a, b]
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