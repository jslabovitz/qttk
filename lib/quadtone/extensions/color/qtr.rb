# "Color" in QTR calibration mode.

module Color
  
  class QTR < Gray
  
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
    
    Channels = %w{LLK LK LM LC Y M C K}.map { |ch| sym = ch.to_sym; const_set(ch, sym); sym }
  
    attr_accessor :channel_num
  
    def self.from_rgb(r, g, b)
      channel = Channels.index(Channels.find { |c| r == 255 - (1 << Channels.index(c)) })
      value = (255 - g) / 255.0
      new(channel, value)
    end
    
    def self.from_cgats(r, g, b)
      from_rgb(r, g, b)
    end
    
    def initialize(channel, value)
      super(value)
      @channel_num = case channel
      when String, Symbol
        Channels.index(channel.to_s.upcase.to_sym) or raise "Unknown channel: #{channel.inspect}"
      when Numeric
        channel
      else
        raise "Unknown channel type: #{channel.inspect}"
      end
    end
    
    def channel
      Channels[@channel_num]
    end
    
    def to_rgb
      [
        255 - (1 << @channel_num),
        (255 - (255 * @value)).to_i,
        255
      ]
    end
        
    def to_cgats
      to_rgb
    end
    
    def html
      '#' + (to_rgb.map { |n| "%02x" % n }.join)
    end
    
    def hash
      [@channel_num, @value].hash
    end
    
    def eql?(other)
      [@channel_num, @value] == [other.channel_num, other.value]
    end
  
    def inspect
      "<%s: %.2f>" % [channel || @channel_num, @value * 100]
    end
    
  end
  
end