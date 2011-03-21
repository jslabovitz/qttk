# "Color" in QTR calibration mode.

module Color
  
  class QTR
  
=begin

    QTR channel map (in calibration mode):

      R:

        (inverse bitmask for channels)

        7: K	 = 127 (01111111)
        6: C	 = 191 (10111111)
        5: M	 = 223 (11011111)
        4: Y	 = 239 (11101111)
        3: LC	 = 247 (11110111)
        2: LM	 = 251 (11111011)
        1: LK	 = 253 (11111101)
        0: LLK = 254 (11111110)

      G:
        0-255

      B:
        should always be 255

      For background, use R=127 / G=255 / B=255
=end
    
    Channels = %w{LLK LK LM LC Y M C K}.map { |s| sym = s.to_sym; const_set(s, sym); sym }
  
    attr_accessor :channel_num
    attr_accessor :value
  
    def self.from_rgb(r, g, b)
      new(r, g, b)
    end
    
    def initialize(*args)
      if args.length == 2 # channel_num, value
        channel, value = *args
        case channel
        when String, Symbol
          @channel_num = Channels.index(channel.to_s.upcase.to_sym) or raise "Unknown channel: #{channel.inspect}"
        else
          @channel_num = channel
        end
        @value = value
      else # r, g, b
        raise "value out of range: #{args.inspect}" if args.find { |a| a > 0 && a < 1 }
        rgb = Color::RGB.new(*args)
        @channel_num = Channels.index(Channels.find { |i| rgb.red == 255 - (1 << Channels.index(i)) })
        @value = rgb.green / 255.0
      end
    end
    
    def channel_key
      Channels[@channel_num]
    end
    
    def to_rgb
      Color::RGB.new(
        255 - (1 << @channel_num),
        (255 * @value).to_i,
        255)
    end
    
    def to_grayscale
      Color::GrayScale.from_fraction(@value)
    end
    
    def density
      to_grayscale.density
    end
    
    def html
      to_rgb.html
    end
    
    def inspect
      "QTR [%s: %.2f]" % [@channel_num, @value]
    end
    
    def hash
      [@channel_num, @value].hash
    end
    
    def eql?(other)
      [@channel_num, @value] == [other.channel_num, other.value]
    end
  
  end
  
end