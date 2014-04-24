module Quadtone

  class CurveSet

    attr_accessor :profile
    attr_accessor :channels
    attr_accessor :type
    attr_accessor :curves

    def initialize(params={})
      @curves = []
      params.each { |key, value| send("#{key}=", value) }
      raise "Profile must be specified" unless @profile
      raise "Channels must be specified" unless @channels
      raise "Type must be specified" unless @type
      @target = Target.new(name: @type.to_s, channels: @channels, base_dir: @profile.dir_path, type: @type)
      generate_scale
    end

    def build_target
      @target.build
    end

    def print_target
      @profile.print_file(@target.image_file, calibrate: (@type == :characterization), print: true)
    end

    def measure_target(options={})
      @target.measure(options)
      process_target
    end

    def process_target
      case @type
      when :characterization
        import_from_target
        set_common_white
        trim_to_limits
        @profile.ink_limits = Hash[
          @curves.map do |curve|
            [
              curve.channel,
              curve.samples.last.input.value
            ]
          end
        ]
        normalize_curves
        @profile.ink_partitions = partitions
      when :linearization, :test
        import_from_target
        if @type == :linearization
          @profile.linearization = grayscale(21)
        elsif @type == :test
          @profile.grayscale = grayscale(21)
        end
      end
      @profile.save
      @profile.install
    end

    def chart_target
      import_from_target
      out_file = (@profile.dir_path + @type.to_s).with_extname('.html')
      out_file.open('w') { |io| io.write(to_html) }
      ;;warn "Saved chart to #{out_file.to_s.inspect}"
    end

    private

    def import_from_target
      @target.read
      @curves.each do |curve|
        curve.samples = @target.samples[curve.channel]
      end
    end

    def generate_scale
      @curves = @channels.map do |channel|
        Curve.new(channel: channel, samples: [
          Sample.new(input: Color::Gray.new(k: 0), output: Color::Lab.new(l: 100)),
          Sample.new(input: Color::Gray.new(k: 1), output: Color::Lab.new(l: 0))
        ])
      end
    end

    def channels
      @curves.map(&:channel)
    end

    def trim_to_limits
      @curves.each { |c| c.trim_to_limit }
    end

    def normalize_curves
      @curves.each { |c| c.normalize_inputs }
    end

    # find average shade of paper, and update each curve to have that average as its first value

    def set_common_white
      samples = samples_with_value(0)
      outputs = samples.map(&:output)
      average, error = Color::Lab.average(outputs)
      raise "too much variance in white samples: average = #{average}, error = #{error}" if error >= 1
      samples.each { |s| s.output = average }
    end

    def samples_with_value(value)
      @curves.map { |c| c.samples.find { |s| s.input_value == value } }.compact.flatten
    end

    def partitions
      partitions = {}
      previous_curve = nil
      @curves.sort_by(&:dmax).reverse.each do |curve|
        ;;warn "processing #{curve.channel}"
        last_sample = curve.samples.last
        if previous_curve
          partitions[curve.channel] = previous_curve.input_for_output(last_sample.output.value) * partitions[previous_curve.channel]
          ;;warn "\t" + "value on previous curve for dmax #{last_sample.output.value} = #{partitions[curve.channel]}"
        else
          partitions[curve.channel] = last_sample.input.value
          ;;warn "\t" + "using absolute value of curve for dmax #{last_sample.output.value} = #{partitions[curve.channel]}"
        end
        previous_curve = curve
      end
      partitions
    end

    def grayscale(steps)
      raise "Can't get gray scale of non-grayscale curveset" if @channels.length > 1
      @curves.first.grayscale(steps)
    end

    def to_html
      html = Builder::XmlMarkup.new(indent: 2)
      html.div do
        html.ul do
          html.li("Channels: #{@channels.join(', ')}")
        end
        html.h3('Curve set:')
        html.table(border: 1) do
          html.tr do
            [
              'channel',
              'ink limit',
              'density: min',
              'density: max',
              'density: range',
            ].each { |s| html.th(s) }
          end
          @curves.each do |curve|
            html.tr do
              dmin, dmax = curve.dynamic_range
              [
                curve.channel.to_s,
                curve.ink_limit.input,
                '%.2f' % dmin,
                '%.2f' % dmax,
                '%.2f' % (dmax - dmin),
              ].each { |s| html.td(s) }
            end
          end
        end
        html << to_svg
      end
      html.target!
    end

    def to_svg(options={})
      size = options[:size] || 500
      svg = Builder::XmlMarkup.new(indent: 2)
      svg.svg(xmlns: 'http://www.w3.org/2000/svg', version: '1.1') do
        svg.g(width: size, height: size, transform: "translate(0,#{size}) scale(1,-1)") do
          svg.g(stroke: 'blue') do
            svg.rect(x: 0, y: 0, width: size, height: size, fill: 'none', :'stroke-width' => 1)
            svg.line(x1: 0, y1: 0, x2: size, y2: size, :'stroke-width' => 0.5)
          end
          @curves.each do |curve|
            curve.draw_svg(svg, options)
          end
        end
      end
      svg.target!
    end

  end

end