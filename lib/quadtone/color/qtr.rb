# "Color" in QTR calibration mode.

module Color

  class QTR < Base

=begin

    QTR channel map (in calibration mode):

      R: inverse bitmask for channels

        7: K	 = 127 (01111111)
        6: C	 = 191 (10111111)
        5: M	 = 223 (11011111)
        4: Y	 = 239 (11101111)
        3: LC	 = 247 (11110111)
        2: LM	 = 251 (11111011)
        1: LK	 = 253 (11111101)
        0: LLK = 254 (11111110)

      G: value (0-255)

      B: unused -- should always be 255

      For background, use R=127 / G=255 / B=255
=end

    Channels = [:llk, :lk, :lm, :lc, :y, :m, :c, :k]

    def self.component_names
      [:channel, :value]
    end

    def self.cgats_fields
      %w{QTR_CHANNEL QTR_VALUE}
    end

    def channel
      @components[0]
    end

    def channel_num
      Channels.index(channel)
    end

    def value
      @components[1]
    end

    def to_rgb
      Color::RGB.new(
        r: (255 - (1 << channel_num)) / 255.0,
        g: (1 - value) / 100,
        b: 1)
    end

    def to_gray
      Color::Gray.new(k: value)
    end

    def to_cgats
      {
        'QTR_CHANNEL' => channel,
        'QTR_VALUE' => value,
      }
    end

  end

end