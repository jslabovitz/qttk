# "Color" in QTR calibration mode.

module Color
  
  class QTR < DeviceN
  
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
    
    ComponentNames = %w{LLK LK LM LC Y M C K}.map { |ch| sym = ch.to_sym; const_set(ch, sym); sym }
    
    attr_accessor :channel
    
    def self.component_names
      ComponentNames
    end
    
    def self.from_rgb(r, g, b)
      channel = ComponentNames.index(ComponentNames.find { |c| r == 255 - (1 << ComponentNames.index(c)) })
      value = (255 - g) / 255.0
      new(channel, value)
    end
    
    def self.cgats_fields
      %w{RGB_R RGB_G RGB_B}
    end
    
    def self.from_cgats(r, g, b)
      from_rgb(r, g, b)
    end
    
    def initialize(channel, value)
      @channel = case channel
      when String, Symbol
        ComponentNames.index(channel.to_s.upcase.to_sym) or raise "Unknown channel: #{channel.inspect}"
      when Numeric
        channel
      else
        raise "Unknown channel type: #{channel.inspect}"
      end
      components = [0] * self.class.num_components
      components[@channel] = value
      super(components)
    end
    
    def value
      @components[@channel]
    end
    
    def channel_name
      ComponentNames[@channel]
    end
    
    def to_rgb
      [
        255 - (1 << @channel),
        (255 - (255 * value)).to_i,
        255
      ]
    end
    
    def to_cgats
      to_rgb
    end
    
    def inspect
      "<%s: %.2f>" % [@channel, value * 100]
    end
    
  end
  
end