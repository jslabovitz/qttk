module Quadtone
  
  class Curve
    
    attr_accessor :key
    attr_accessor :points
    attr_accessor :resolution
    attr_accessor :ink_limit
    
    def initialize(key, points)
      @key = key
      @points = points.sort_by { |p| p.input }
      @resolution = 11
      @min_delta_e = 0.005
      initial_spline = build_spline(@points)
      resampled_points = input_scale(@resolution).map { |input| Point.new(input, initial_spline.eval(input)) }
      @spline = build_spline(resampled_points)
      find_ink_limit!
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def build_spline(points)
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
      GSL::Spline.alloc(type, inputs, outputs)
    end
  
    def [](input)
      @spline.eval(input)
    end
    
    def input_scale(steps=21)
      range = @points.first.input .. @points.last.input
      range.step(1.0 / (steps - 1)).to_a
    end
    
    def find_ink_limit!(resolution=100)
      @ink_limit = @points.last
      scale = input_scale(resolution)
      scale.each_with_index do |input, i|
        next_input = scale[i + 1] or next
        output = self[input]
        next_output = self[next_input]
        delta_e = next_output - output
        if delta_e < @min_delta_e
          @ink_limit = Point.new(input, output)
          break
        end
      end
    end
        
    def num_points
      @points.length
    end
    
    def dump
      ;;warn "#{key}: (#{@points.length}) " + @points.map { |p| "%11s" % [p.input, p.output, self[p.input]].map { |n| (n*100).to_i }.join('/') }.join(' ')
    end
  
    def find_relative_density(output, resolution=100)
      relative = input_scale(resolution).find { |input| output <= self[input] }
      #FIXME: Scale like this?
      # relative *= max_input_density
      relative
    end
    
    class Point < Struct.new(:input, :output, :stdev); end
    
  end
  
end