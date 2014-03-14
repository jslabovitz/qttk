module Color

  class CMYK < Base

    def self.component_names
      [:c, :m, :y, :k, :lc, :lm, :lk, :llk]
    end

    def self.cgats_fields
      %w{CMYKcmk1k_C CMYKcmk1k_M CMYKcmk1k_Y CMYKcmk1k_K
         CMYKcmk1k_c CMYKcmk1k_m CMYKcmk1k_k CMYKcmk1k_1k}
    end

    def self.cgats_color_rep
      'CMYKcmk1k'
    end

    def c
      @components[0]
    end

    def m
      @components[1]
    end

    def y
      @components[2]
    end

    def k
      @components[3]
    end

    def lc
      @components[4]
    end

    def lm
      @components[5]
    end

    def lk
      @components[6]
    end

    def llk
      @components[7]
    end

    def to_cgats
      {
        'CMYKcmk1k_C'  => c,
        'CMYKcmk1k_M'  => m,
        'CMYKcmk1k_Y'  => y,
        'CMYKcmk1k_K'  => k,
        'CMYKcmk1k_c'  => lc,
        'CMYKcmk1k_m'  => lm,
        'CMYKcmk1k_k'  => lk,
        'CMYKcmk1k_1k' => llk,
      }
    end

    def to_cmyk
      # estimates for light & light-light inks
      l_factor = 0.5
      ll_factor = 0.25

      # first adjust for light inks
      c0 = c + (lc * l_factor)
      m0 = m + (lm * l_factor)
      y0 = y
      k0 = k + (lk * l_factor) + (llk * ll_factor)

      Color::CMYK.new([c0, m0, y0, k0])
    end

    def to_cmy
      # after http://www.easyrgb.com/index.php?X=MATH&H=14#text14

      c0, m0, y0, k0 = *to_cmyk
      c0 /= 100.0
      m0 /= 100.0
      y0 /= 100.0
      k0 /= 100.0

      c0 = (c0 * (1 - k0)) + k0
      m0 = (m0 * (1 - k0)) + k0
      y0 = (y0 * (1 - k0)) + k0

      Color::CMYK.new([c0 * 100, m0 * 100, y0 * 100])
    end

    def to_rgb
      cmy = to_cmy
      Color::RGB.new([1 - (cmy.c / 100), 1 - (cmy.m / 100), 1 - (cmy.y / 100)])
    end

    def to_lab
      to_xyz.to_lab
    end

    def to_xyz
      to_rgb.to_xyz
    end

    def to_a
      @components
    end

  end

end