module Color

  class Gray < Base

    def self.component_names
      [:k]
    end

    def self.cgats_fields
      %w{GRAY_K}
    end

    def self.cgats_color_rep
      'K'
    end

    def k
      @components[0]
    end

    def value
      k / 100.0
    end

    def to_cgats
      {
        'GRAY_K' => k,
      }
    end

    def to_rgb
      n = 1 - value
      Color::RGB.new([n, n, n])
    end

    def to_lab
      Color::Lab.new(l: 100 - k, a: 0, b: 0)
    end

    def to_xyz
      to_lab.to_xyz
    end

  end

end