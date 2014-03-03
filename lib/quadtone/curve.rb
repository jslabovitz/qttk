module Quadtone

  class Curve

    attr_accessor :key
    attr_accessor :samples
    attr_accessor :limit
    attr_accessor :density_limit
    attr_accessor :delta_e_limit

    def initialize(key, samples, limit=1.0)
      @key = key
      @samples = samples.sort_by(&:input)
      @limit = limit
      points = @samples.map { |s| Spline::Point.new(s.input, s.output) }
      @spline = Spline.new(points)
    end

    def [](input)
      @spline.interpolate(input).y
    end

    def interpolated_samples(steps)
      range = @samples.first.input .. @samples.last.input
      range.step(1.0 / (steps - 1)).map do |value|
        Sample.new(value, self[value])
      end
    end

    def num_samples
      @samples.length
    end

    def find_relative_value(desired, resolution=100)
      interpolated_samples(resolution).find { |sample| desired <= sample.output }.input
    end

    def find_limits!
      samples = interpolated_samples(100)
      @density_limit = samples.sort_by { |p| p.output }.last
      @delta_e_limit = nil
      (0 .. samples.length - 2).each do |i|
        sample, next_sample = samples[i], samples[i + 1]
        delta_e = Color::Gray.new(sample.output).to_lab.delta_e(Color::Gray.new(next_sample.output), :density)
        if delta_e < 0.3
          @delta_e_limit = sample
          break
        end
      end
    end

    # def limit
    #   # find minimum of density and delta_e
    #   [@density_limit, @delta_e_limit].compact.sort_by { |pt| pt.input }.first
    # end

    def dmin
      @samples.first.output
    end

    def dmax
      @samples.last.output
    end

    def dynamic_range
      [dmin, dmax]
    end

  end

end