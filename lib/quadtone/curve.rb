module Quadtone
  
  class Curve
    
    attr_accessor :key
    attr_accessor :points
    attr_accessor :resolution
    
    def initialize(key, points)
      @key = key
      @points = points.sort_by { |p| p.input }
      @resolution = 11
      initial_spline = Spline.new(@points)
      resampled_points = input_scale(@resolution).map { |input| Point.new(input, initial_spline[input]) }
      @spline = Spline.new(resampled_points)
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def [](input)
      @spline[input]
    end
    
    def input_scale(steps=21)
      range = @points.first.input .. @points.last.input
      range.step(1.0 / (steps - 1)).to_a
    end
    
    def num_points
      @points.length
    end
      
    def find_relative_density(output, resolution=100)
      relative = input_scale(resolution).find { |input| output <= self[input] }
      #FIXME: Scale like this?
      # relative *= max_input_density
      relative
    end
    
    def ink_limit
      #FIXME
      @points.last
    end
    
    def ink_limits
      #FIXME
      {
        :chroma => @points.last,
        :density => @points.last,
      }
    end
    
    class Point < Struct.new(:input, :output, :stdev); end
    
    class Spline
      
      def initialize(points)
        if points.length >= 5
          type = 'akima'
        elsif points.length >= 3
          type = 'cspline'
        elsif points.length >= 2
          type = 'linear'
        else
          raise "Curve must have at least two points"
        end
        inputs = GSL::Vector[points.length]
        outputs = GSL::Vector[points.length]
        points.each_with_index do |point, i|
          inputs[i]  = point.input
          outputs[i] = point.output ? point.output : point.input
        end
        @gsl_spline = GSL::Spline.alloc(type, inputs, outputs)
      end
      
      def [](input)
        @gsl_spline.eval(input)
      end
      
    end
    
  end
  
end