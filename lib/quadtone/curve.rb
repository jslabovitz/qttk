module Quadtone

  class Curve

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

    def find_ink_limit
      # ;;@samples.each { |s| warn "%s-%s: %.2f => %.2f" % [@channel, s.id, s.input.value, s.output.value] }
      previous_sample = nil
      @samples.each do |sample|
        if previous_sample
          delta_e = previous_sample.output.delta_e(sample.output)
          # ;;warn "#{previous_sample} ~ #{sample} = #{delta_e}"
          return previous_sample if delta_e < 0.3
        end
        previous_sample = sample
      end
      nil
    end

    def trim_to_limit
      if (sample = find_ink_limit)
        i = @samples.index(sample)
        ;;warn "trimming curve #{@channel} to sample \##{i}: #{sample}"
        @samples.slice!(i + 1 .. -1)
        @input_spliner = @output_spliner = nil
      end
    end

    def normalize_inputs
      scale = 1 / @samples.last.input.value
      @samples.each do |sample|
        sample.input = Color::Gray.new(k: sample.input.k * scale)
      end
      @input_spliner = @output_spliner = nil
    end

    def density_limit
      @density_limit ||= @samples.sort_by(&:output).last
    end

    def delta_e_limit
      unless @delta_e_limit
        (0 .. @samples.length - 2).each do |i|
          sample, next_sample = samples[i], samples[i + 1]
          delta_e = sample.output.delta_e(next_sample.output, :density)
          if delta_e < 0.3
            @delta_e_limit = sample
            break
          end
        end
      end
      @delta_e_limit
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

      # draw individual samples
      @samples.each do |sample|
        svg.circle(cx: size * sample.input_value, cy: size * sample.output_value, r: 2, stroke: 'none', fill: "rgb(#{sample.output.to_rgb.to_a.join(',')})")
        if sample.error && sample.error > 0.05
          svg.circle(cx: size * sample.input_value, cy: size * sample.output_value, r: 2 + (sample.error * 10), stroke: 'red', fill: 'none')
        end
      end

      # draw interpolated curve
      samples = (0..1).step(1.0 / size).map do |n|
        [size * n, size * output_for_input(n)]
      end
      svg.g(fill: 'none', stroke: 'green', :'stroke-width' => 1) do
        svg.polyline(points: samples.map { |pt| pt.join(',') }.join(' '))
      end

      # # draw marker for ink limit (density)
      # if (limit = density_limit)
      #   x, y = size * limit.input, size * limit.output
      #   svg.g(stroke: 'black', :'stroke-width' => 2) do
      #     svg.line(x1: x, y1: y + 8, x2: x, y2: y - 8)
      #   end
      # end

      # # draw marker for ink limit (delta E)
      # if (limit = delta_e_limit)
      #   x, y = size * limit.input, size * limit.output
      #   svg.g(stroke: 'cyan', :'stroke-width' => 2) do
      #     svg.line(x1: x, y1: y + 8, x2: x, y2: y - 8)
      #   end
      # end

      svg.target!
    end

  end

end