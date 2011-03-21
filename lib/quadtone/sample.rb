module Quadtone
  
  class Sample
  
    attr_accessor :input
    attr_accessor :output
        
    def self.from_cgats_data(set)
      sample = new(nil, nil)
      sample.parse_cgats_data!(set)
      sample
    end
  
    def initialize(input, output)
      @input = input
      @output = output
    end
  
    def parse_cgats_data!(set)
      Target::Fields.each do |klass, fields|
        if set[fields.first]
          color = klass.new(*fields.map { |f| set[f] })
          case color
          when Color::QTR
            @input = color
          when Color::GrayScale
            color.g = 1 - color.g
            @input = color
          when Color::Lab
            @output = color
          else
            raise "Can't parse CGATS data: #{set.inspect}"
          end
        end
      end
    end
        
    def to_cgats_data
      data = []
      case @input
      when Color::QTR
        rgb = @input.to_rgb
        data.concat([rgb.red.to_i, rgb.green.to_i, rgb.blue.to_i])
      when Color::GrayScale
        data.concat([100 - @input.gray])
      else
        raise "Can't convert to CGATS data: #{inspect}"
      end
      data.concat([@output.l, @output.a, @output.b]) if @output
      data
    end
  
  end
  
end