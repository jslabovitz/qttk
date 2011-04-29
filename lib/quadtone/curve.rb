module Quadtone
  
  class Curve
    
    attr_accessor :key
    attr_accessor :samples
    attr_accessor :resolution
    attr_accessor :chroma_limit
    attr_accessor :density_limit
    attr_accessor :delta_e_limit
    
    def initialize(key, samples)
      @key = key
      @samples = samples.sort_by(&:input)
      @resolution = 11
      @spline = Spline.new(@samples)
      @spline = Spline.new(interpolated_samples(@resolution))
    end
    
    def to_yaml_properties
      super - [:@spline]
    end
    
    def [](input)
      @spline[input]
    end
    
    def interpolated_samples(steps)
      range = @samples.first.input.value .. @samples.last.input.value
      range.step(1.0 / (steps - 1)).map do |v|
        input = Color::Gray.new(v)
        Sample.new(input, self[input])
      end
    end
    
    def num_samples
      @samples.length
    end
    
    def find_relative_value(desired, resolution=100)
      interpolated_samples(resolution).find { |sample| desired.value <= sample.output.value }.input
    end
    
    def find_ink_limits!
      samples = interpolated_samples(100)
      @density_limit = samples.sort_by { |p| p.output.value }.last
      @chroma_limit = samples.sort_by { |p| p.output.chroma }.first
      @delta_e_limit = nil
      (0 .. samples.length - 2).each do |i|
        sample, next_sample = samples[i], samples[i + 1]
        delta_e = sample.output.delta_e(next_sample.output, :density)
        if delta_e < 0.3
          @delta_e_limit = sample
          break
        end
      end
    end
    
    def ink_limit
      # find minimum of chroma, density, delta_e
      [@chroma_limit, @density_limit, @delta_e_limit].sort_by { |pt| pt.input.value }.first
    end
        
    class Spline
      
      def initialize(samples)
        if samples.length >= 5
          type = 'akima'
        elsif samples.length >= 3
          type = 'cspline'
        elsif samples.length >= 2
          type = 'linear'
        else
          raise "Curve must have at least two samples"
        end
        @color_class = samples.first.output.class
        @gsl_splines = {}
        @color_class.component_names.each_with_index do |component_name, component_index|
          inputs = GSL::Vector[samples.length]
          outputs = GSL::Vector[samples.length]
          samples.each_with_index do |sample, i|
            inputs[i]  = sample.input.value
            outputs[i] = sample.output.components[component_index]
          end
          @gsl_splines[component_name] = GSL::Spline.alloc(type, inputs, outputs)
        end
      end
      
      def [](input)
        component_values = @color_class.component_names.map do |component_name|
          @gsl_splines[component_name].eval(input.value)
        end
        @color_class.new(*component_values)
      end
      
    end
    
  end
  
end