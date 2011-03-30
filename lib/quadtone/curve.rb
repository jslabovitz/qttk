module Quadtone
  
  class Curve
  
    attr_accessor :key
    attr_accessor :samples
  
    def initialize(key, samples)
      @key = key
      @samples = samples
      build_spline!
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def build_spline!
      @samples.sort_by! { |s| s.input.density }
      if @samples.length >= 5
        type = 'akima'
      elsif @samples.length >= 3
        type = 'cspline'
      elsif @samples.length >= 2
        type = 'linear'
      else
        raise "Need at least two samples: #{@samples.inspect}"
      end
      inputs = GSL::Vector[@samples.length]
      outputs = GSL::Vector[@samples.length]
      @samples.each_with_index do |sample, i|
        inputs[i]  = sample.input.density
        outputs[i] = sample.output ? sample.output.density : sample.input.density
      end
      @spline = GSL::Spline.alloc(type, inputs.dup, outputs.dup)
    end
  
    def output_for_input(input_density)
      build_spline! unless @spline
      @spline.eval(input_density)
    end

    def ink_limit(resolution=20, min_density=0.1)
      step_amount = 1.0 / resolution
      (min_density..1).step(step_amount).each do |input_density|
        output_density = output_for_input(input_density)
        next_output_density = output_for_input(input_density + step_amount)
        delta_e = next_output_density - output_density
        if delta_e < 0.01
          return Sample.new(Color::GrayScale.from_density(input_density), Color::GrayScale.from_density(output_density))
        end
      end
    end
    
    def trim!(resolution=20, min_density=0.1)
      limit = ink_limit(resolution, min_density) or raise "Can't find ink limit for #{key}"
      sample = @samples.find { |s| s.input.density > limit.input.density }
      i = @samples.index(sample)
      ;;warn "#{key}: trimmed at first sample > #{limit.input.density}: #{sample.input.density} (sample #{i})"
      @samples.slice!(i..-1)
    end
    
    def resample(steps=21)
      step_amount = max_input_density / (steps - 1)
      new_samples = (0..max_input_density).step(step_amount).map do |input_density|
        Sample.new(Color::GrayScale.from_density(input_density), Color::GrayScale.from_density(output_for_input(input_density)))
      end
      self.class.new(@key, new_samples)
    end
    
    def num_samples
      @samples.length
    end
    
    def dump
      ;;warn "#{key}: (#{@samples.length}) " + @samples.map { |s| "%11s" % [s.input.density, s.output.density, output_for_input(s.input.density)].map { |n| (n*100).to_i }.join('/') }.join(' ')
    end
  
    def max_input_density
      @samples.map { |s| s.input.density }.max
    end
  
    def max_output_density
      @samples.map { |s| s.output.density }.max
    end
  
    def find_relative_density(density, resolution=100)
      input_density = (0..1).step(1.0 / resolution).find { |input_density| density <= output_for_input(input_density) }
      #FIXME: Scale like this?
      # ;;warn "scaling #{input_density} by #{max_input_density} => #{input_density * max_input_density}"
      # input_density *= max_input_density
      input_density
    end
  
  end
  
end