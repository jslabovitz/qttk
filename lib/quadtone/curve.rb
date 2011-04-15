module Quadtone
  
  class Curve
    
    attr_accessor :key
    attr_accessor :points
    attr_accessor :resolution
    attr_accessor :chroma_limit
    attr_accessor :density_limit
    attr_accessor :delta_e_limit
    
    def initialize(key, points)
      @key = key
      @points = points.sort_by(&:input)
      @resolution = 11
      @spline = Spline.new(@points)
      resampled_points = input_scale(@resolution)
      @spline = Spline.new(resampled_points)
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def [](input)
      @spline[input]
    end
    
    def input_scale(steps=21)
      range = @points.first.input.value .. @points.last.input.value
      range.step(1.0 / (steps - 1)).map do |v|
        input = Color::Gray.new(v)
        Point.new(input, self[input])
      end
    end
    
    def num_points
      @points.length
    end
    
    def find_relative_value(desired, resolution=100)
      input_scale(resolution).find { |point| desired.value <= point.output.value }.input
    end
    
    def find_ink_limits!
      points = input_scale(100)
      @density_limit = points.sort_by { |p| p.output.value }.last
      @chroma_limit = points.sort_by { |p| p.output.chroma }.first
      @delta_e_limit = nil
      (0 .. points.length - 2).each do |i|
        point, next_point = points[i], points[i + 1]
        delta_e = point.output.delta_e(next_point.output, :density)
        if delta_e < 0.3
          @delta_e_limit = point
          break
        end
      end
    end
    
    def ink_limit
      # find minimum of chroma, density, delta_e
      [@chroma_limit, @density_limit, @delta_e_limit].sort_by { |pt| pt.input.value }.first
    end
    
    class Point < Struct.new(:input, :output, :error); end
    
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
        @color_class = points.first.output.class
        @gsl_splines = {}
        @color_class.components.each do |component|
          inputs = GSL::Vector[points.length]
          outputs = GSL::Vector[points.length]
          points.each_with_index do |point, i|
            inputs[i]  = point.input.value
            outputs[i] = point.output.method(component).call
          end
          @gsl_splines[component] = GSL::Spline.alloc(type, inputs, outputs)
        end
      end
      
      def [](input)
        component_values = @color_class.components.map do |component|
          @gsl_splines[component].eval(input.value)
        end
        @color_class.new(*component_values)
      end
      
    end
    
  end
  
end