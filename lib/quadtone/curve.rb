module Quadtone
  
  class Curve
    
    attr_accessor :key
    attr_accessor :points
    attr_accessor :resolution
    attr_accessor :ink_limit
    
    def initialize(key, points, ink_limit=nil)
      @key = key
      @points = points.sort_by { |p| p.input }
      @ink_limit = ink_limit
      @resolution = 11
      initial_spline = build_spline(@points)
      resampled_points = input_scale(@resolution).map { |input| Point.new(input, initial_spline.eval(input)) }
      @spline = build_spline(resampled_points)
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