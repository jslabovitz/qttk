module Quadtone
  
  class Curve
  
    attr_accessor :key
    attr_accessor :points
    attr_accessor :ink_limit
    
    def initialize(key, points)
      @key = key
      @points = points
      build_spline!
      find_ink_limit!
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def build_spline!
      @points.sort_by! { |p| p.input }
      if @points.length >= 5
        type = 'akima'
      elsif @points.length >= 3
        type = 'cspline'
      elsif @points.length >= 2
        type = 'linear'
      else
        raise "Need at least two points: #{@points.inspect}"
      end
      inputs = GSL::Vector[@points.length]
      outputs = GSL::Vector[@points.length]
      @points.each_with_index do |point, i|
        inputs[i]  = point.input
        outputs[i] = point.output ? point.output : point.input
      end
      @spline = GSL::Spline.alloc(type, inputs.dup, outputs.dup)
    end
  
    def output_for_input(input)
      build_spline! unless @spline
      @spline.eval(input)
    end

    def find_ink_limit!(resolution=100, min_density=0.1)
      @ink_limit = @points.last
      step_amount = 1.0 / resolution
      (min_density..@points.last.input).step(step_amount).each do |input|
        output = output_for_input(input)
        next_output = output_for_input(input + step_amount)
        delta_e = next_output - output
        if delta_e < 0.001
          @ink_limit = Point.new(input, output)
          break
        end
      end
    end
        
    def resample(steps=21)
      step_amount = @points.last.input / (steps - 1)
      new_points = (0..@points.last.input).step(step_amount).map do |input|
        Point.new(input, output_for_input(input))
      end
      self.class.new(@key, new_points)
    end
    
    def num_points
      @points.length
    end
    
    def dump
      ;;warn "#{key}: (#{@points.length}) " + @points.map { |p| "%11s" % [p.input, p.output, output_for_input(p.input)].map { |n| (n*100).to_i }.join('/') }.join(' ')
    end
  
    def find_relative_density(output, resolution=100)
      relative = (0..1).step(1.0 / resolution).find { |input| output <= output_for_input(input) }
      #FIXME: Scale like this?
      # relative *= max_input_density
      relative
    end
    
    class Point < Struct.new(:input, :output, :stdev); end
    
  end
  
end