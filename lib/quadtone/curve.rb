module Quadtone

  class Curve

    DeltaETolerance = 1.0
    DeltaEMethod = :density

    attr_accessor :channel
    attr_accessor :samples

    def initialize(params={})
      params.each { |key, value| send("#{key}=", value) }
    end

    def samples=(samples)
      @samples = samples.sort_by(&:input_value)
    end

    def output_for_input(input)
      @output_spliner ||= Spliner::Spliner.new(@samples.map(&:input_value), @samples.map(&:output_value))
      @output_spliner[input]
    end

    def input_for_output(output)
      @input_spliner ||= Spliner::Spliner.new(@samples.map(&:output_value), @samples.map(&:input_value))
      @input_spliner[output]
    end

    def num_samples
      @samples.length
    end

    def grayscale(steps)
      spliner = Spliner::Spliner.new(Hash[ @samples.map { |s| [s.input.value, s.output.l] } ])
      scale = (0 .. 1).step(1.0 / (steps - 1))
      spliner[scale].map { |l| Color::Lab.new([l]) }
    end

    def ink_limit(method=DeltaEMethod)
      # ;;@samples.each { |s| warn "%s-%s: %.2f => %.2f" % [@channel, s.id, s.input.value, s.output.value] }
      @samples.each_with_index do |sample, i|
        if i > 0
          previous_sample = @samples[i - 1]
          return previous_sample if sample.output_value < previous_sample.output_value
          return previous_sample if previous_sample.output.delta_e(sample.output, method) < DeltaETolerance
        end
      end
      @samples.last
    end

    def trim_to_limit
      limit = ink_limit
      i = @samples.index(limit)
      ;;warn "trimming curve #{@channel} to sample \##{i}: #{limit}"
      @samples.slice!(i + 1 .. -1)
      @input_spliner = @output_spliner = nil
    end

    def normalize_inputs
      scale = 1 / @samples.last.input.value
      @samples.each do |sample|
        sample.input = Color::Gray.new(k: sample.input.k * scale)
      end
      @input_spliner = @output_spliner = nil
    end

    def verify_increasing_values
      @samples.each_with_index do |sample, i|
        if i > 0
          previous_sample = @samples[i - 1]
          if sample.output_value < previous_sample.output_value
            raise "Samples not in increasing order (#{sample.label} [#{i}]: #{sample.output_value} < #{previous_sample.output_value})"
          end
        end
      end
    end

    def dmin
      @samples.first.output_value
    end

    def dmax
      @samples.last.output_value
    end

    def dynamic_range
      [dmin, dmax]
    end

    def draw_svg(svg, options={})
      size = options[:size] || 500

      # draw interpolated curve
      svg.g(fill: 'none', stroke: 'green', :'stroke-width' => 1) do
        samples = (0..1).step(1.0 / size).map do |n|
          [size * n, size * output_for_input(n)]
        end
        svg.polyline(points: samples.map { |pt| pt.join(',') }.join(' '))
      end

      # draw markers for ink limits
      {
        density: 'gray',
        # cie76: 'red',
        # cie94: 'green',
        # cmclc: 'blue',
      }.each do |method, color|
        limit = ink_limit(method)
        x, y = size * limit.input_value, size * limit.output_value
        svg.g(stroke: color, :'stroke-width' => 3) do
          svg.line(x1: x, y1: y + 8, x2: x, y2: y - 8)
        end
      end

      # if (limit = ink_limit)
      #   x, y = size * limit.input_value, size * limit.output_value
      #   svg.g(stroke: 'black', :'stroke-width' => 3) do
      #     svg.line(x1: x, y1: y + 15, x2: x, y2: y - 15)
      #   end
      # end

      # draw individual samples
      @samples.each_with_index do |sample, i|
        svg.circle(
          cx: size * sample.input_value,
          cy: size * sample.output_value,
          r: 3,
          stroke: 'none',
          fill: "rgb(#{sample.output.to_rgb.to_a.join(',')})",
          title: sample.label)
      end

      svg.target!
    end

  end

end