module Quadtone
  
  class Sample
  
    attr_accessor :input
    attr_accessor :output
    attr_accessor :error
        
    def self.from_cgats_data(set)
      sample = new(nil, nil)
      sample.parse_cgats_data!(set)
      sample
    end
  
    def initialize(input, output, error=nil)
      @input = input
      @output = output
      @error = error
    end
  
    def parse_cgats_data!(set)
      Color::Base.descendants.each do |color_class|
        data = color_class.cgats_fields.map { |f| set[f] }.compact
        if data.length > 0
          color = color_class.from_cgats(*data)
          case color
          when Color::Lab
            @output = color
          else
            @input = color
          end
        end
      end
    end
        
    def to_cgats_data
      [@input.to_cgats, @output ? @output.to_cgats : []].flatten
    end
  
  end
  
end