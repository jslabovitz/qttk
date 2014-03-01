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
    RedChannelMap = Hash[
      ComponentNames.map { |c|
        [(255 - (1 << ComponentNames.index(c))), c]
      }
    ]
    
    attr_accessor :channel
    
    def self.component_names
      ComponentNames
    end
    
    def self.cgats_fields
      %w{QTR_CHANNEL QTR_VALUE}
    end
    
    def self.from_cgats(set)
      channel, value = set.values_at(*cgats_fields)
      new(channel, value / 100.0)
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
      Color::RGB.new(
        (255 - (1 << @channel)) / 255.0,
        1 - value, 
        1)
    end
    
    def to_pixel
      Magick::Pixel.new(*to_rgb.to_a.map { |n| n * Magick::QuantumRange })
    end
    
    def to_cgats
      {
        'QTR_CHANNEL' => channel_name,
        'QTR_VALUE' => value * 100,
      }
    end
    
    def inspect
      "<%s: %3d%%>" % [channel_name, value * 100]
    end
    
  end
  
end