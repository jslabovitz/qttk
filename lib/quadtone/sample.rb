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
        data = fields.map { |f| set[f] }.compact
        if data.length > 0
          color = klass.from_cgats(*data)
          if color.kind_of?(Color::Lab)
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