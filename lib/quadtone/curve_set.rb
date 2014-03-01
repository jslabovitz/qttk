module Quadtone

  class CurveSet

    attr_accessor :color_class
    attr_accessor :channels
    attr_accessor :curves
    attr_accessor :limits
    attr_accessor :paper

    def self.from_quad_file(quad_file)
      curve_set = new(:color_class => Color::QTR)
      curve_set.read_quad_file!(quad_file)
      curve_set
    end

    def self.from_ti3_file(ti3_file, color_class)
      curve_set = new(:color_class => color_class)
      curve_set.read_ti3_file!(ti3_file)
      curve_set
    end

    def initialize(params={})
      params.each { |key, value| method("#{key}=").call(value) }
      @channels ||= @color_class.component_names if @color_class
      @curves = []
      @paper = nil
      @limits = {}
      generate_scale
    end

    def generate_scale
      @curves = @channels.map do |channel|
        samples = [
          Sample.new(0, 0),
          Sample.new(1, 1)
        ]
        Curve.new(channel, samples, @limits[channel])
      end
    end

    # def build_target(name)
    #   write_ti1_file("#{name}.ti1")
    #   run('printtarg',
    #     '-i', 'i1',           # set instrument to EyeOne (FIXME: make configurable)
    #     '-b',                 # force B&W spacers
    #     '-t', 360,            # generate 8-bit TIFF @ 360 ppi
    #     '-r',                 # Don't randomize
    #     # '-R', 1,              # start random seed at 1
    #     '-p', 'Letter',       # format for letter-sized page
    #     '-m', 12,
    #     name)
    # end

    # def build_target(name)
    #   image_list = Magick::ImageList.new
    #   tile_width = tile_height = nil
    #   @channels.each do |channel|
    #     sub_name = "#{name}-#{channel}"
    #     ;;warn "Making target #{sub_name.inspect}"
    #     run('targen',
    #       '-d', 0,              # generate grayscale target
    #       sub_name)
    #     run('printtarg',
    #       '-i', 'i1',           # set instrument to EyeOne (FIXME: make configurable)
    #       '-b',                 # force B&W spacers
    #       '-t', 360,            # generate 8-bit TIFF @ 360 ppi
    #       '-r',                 # Don't randomize
    #       # '-R', 1,              # start random seed at 1
    #       '-p', '38x260',       # page size just big enough to hold this target
    #       '-L',                 # suppress paper clip border
    #       '-M', 0,              # zero margin
    #       sub_name)
    #     image = Magick::Image.read("#{sub_name}.tif").first
    #     tile_width ||= image.columns
    #     tile_height ||= image.rows
    #     if color_class == Color::QTR
    #       # get the RGB values for a black pixel for this channel in QTR calibration mode
    #       rgb = Color::QTR.new(channel, 0).to_rgb.to_a.map { |c| c * Magick::QuantumRange }
    #       image = image.colorize(1, 0, 1, Magick::Pixel.new(*rgb))
    #     end
    #     image_list << image
    #   end
    #   image_list = image_list.montage do
    #     self.geometry = Magick::Geometry.new(tile_width, tile_height)
    #     self.tile = Magick::Geometry.new(image_list.length, 1)
    #   end
    #   # image_list.first.rows = 8 * 360
    #   # image_list.first.columns = 10 * 360
    #   image_list.write("#{name}.tif")
    #   @channels.each do |channel|
    #     Pathname.new("#{name}-#{channel}.tif").unlink
    #   end
    # end

    def build_target(name)
      write_ti1_file("#{name}.ti1")
      target = Target.new(@color_class, 8.in, 10.5.in)   #FIXME: use smaller area
      target.read_ti1_file!("#{name}.ti1")
      target.write_ti2_file("#{name}.ti2")
      target.write_image_file("#{name}.tif")
    end

    def measure_target(name)
      puts; puts "Ready to measure #{name}"
      run('chartread',
        '-N',   # disable auto calibration unless first time through
        '-n',   # don't save spectral info
        '-l',   # save L*a*b rather than XYZ
        '-H',   # use high resolution spectrum mode
        name)
    end

    # def measure_target(name)
    #   @channels.each_with_index do |channel, i|
    #     sub_name = Pathname.new("#{name}-#{channel}")
    #     ti2_path = sub_name.with_extname('.ti2')
    #     ti3_path = sub_name.with_extname('.ti3')
    #     if !ti3_path.exist? || ti3_path.mtime < ti2_path.mtime
    #       puts; puts "Ready to read #{sub_name} ('q' to skip): "
    #       case STDIN.gets.chomp
    #       when 'q'
    #         next
    #       end
    #       run('chartread',
    #         (i > 0) ? '-N' : nil,   # disable auto calibration unless first time through
    #         '-n',                   # don't save spectral info
    #         '-l',                   # save L*a*b rather than XYZ
    #         '-H',                   # use high resolution spectrum mode
    #         sub_name)
    #     end
    #   end
    # end

    def read_ti3_file!(ti3_file)
      cgats = CGATS.new_from_file(ti3_file)

      # read patches from CGATS file, and store per channel
      values = Hash.new(Hash.new([]))
      cgats.sections.first.data.each do |set|

        input = @color_class.new(set.values_at(@color_class.cgats_fields))
        output = Color::Lab.new(set.values_at(Color::Lab.cgats_fields))

        values[input.channel_name][input] << output
      end

      # average multiple readings
      values.each do |channel, inputs|
        values[channel] = inputs.sort.map do |input, outputs|
          average_output, error = outputs.first.class.average(outputs)
          warn "sample error out of range: input=#{input.inspect}, outputs=#{outputs.inspect}, error=#{error}" if error && error >= 1
          sample = Sample.new(input.value, average_output.value, error)
          sample
        end
      end

      # find average shade of paper, and update each curve to have that average as its first value
      paper_shades = values.map { |c| c.first.output }
      average_paper_shade, error = Color::Lab.average(paper_shades)
      warn "average paper shade error out of range: input=#{input.inspect}, paper_shades=#{paper_shades.inspect}, error=#{error}" if error && error >= 1
      @paper = average_paper_shade
      values.map { |c| c.first.output = @paper }

      # create actual curves
      @curves = []
      values.each do |channel, samples|
        curve = Curve.new(channel, samples)
        curve.find_limits!
        if curve.limit.input == 0
          warn "Ignoring ink #{channel} because limit is zero"
        else
          @curves << curve
        end
      end
      @curves.sort_by! { |c| @channels.index(c.key) }

      warn "read #{samples.length} samples covering channels: #{@curves.map { |c| c.key }.join(' ')}"
    end

    ChannelAliases = {
      'c' => :LC,
      'm' => :LM,
      'k' => :LK,
    }

    # Read QTR quad (curve) file

    def read_quad_file!(quad_file)
  		lines = Pathname.new(quad_file).open.readlines.map { |line| line.chomp.force_encoding('ISO-8859-1') }

  	  # process header
  	  line = lines.shift
      line =~ /^##\s+QuadToneRIP\s+(.*)$/ or raise "Unexpected header value: #{line.inspect}"
  		# "## QuadToneRIP K,C,M,Y,LC,LM"
  		# "## QuadToneRIP KCMY"
      channel_list = $1
      @curves = ($1.split(channel_list =~ /,/ ? ',' : //)).map { |c| ChannelAliases[c] || c.to_sym }.map do |channel|
        samples = (0..255).to_a.map do |input|
          lines.shift while lines.first =~ /^#/
          line = lines.shift
          line =~ /^(\d+)$/ or raise "Unexpected value: #{line.inspect}"
          output = $1.to_i
          Sample.new(input / 255.0, output / 65535.0)
  			end
        # curve = nil if curve.empty? || curve.uniq == [0]
  		  Curve.new(channel, samples)
  		end
    end

    def num_channels
      @curves.length
    end

    def separations
      curves = @curves.sort_by { |c| c.limit.output }.reverse
      darkest_curve = curves.shift
      separations = { darkest_curve.key => darkest_curve.samples.last.input }
      separations
    end

    def paper_value
      if @paper
        @paper.output
      end
    end

    def write_ti1_file(cgats_path)
      cgats_path = Pathname.new(cgats_path)
      cgats = CGATS.new

      num_steps = 51
      # ;;num_steps = 2
      color_rep = (@color_class == Color::QTR) ? 'QTR' : 'K'
      white_color_patches = 4

      # section 1: SINGLE_DIM_STEPS
      section = CGATS::Section.new
      section.header = {
        'CTI1' => nil,
        'DESCRIPTOR' => 'Argyll Calibration Target chart information 1',
        'ORIGINATOR' => 'qttk',
        'CREATED' => DateTime.now.to_s,
        # 'APPROX_WHITE_POINT' => "95.106486 100.000000 108.844025",
        'COLOR_REP' => color_rep,
        'WHITE_COLOR_PATCHES' => white_color_patches,
        'SINGLE_DIM_STEPS' => num_steps,
      }
      section.data_fields = %w{SAMPLE_ID} + @color_class.cgats_fields + Color::XYZ.cgats_fields
      sample_id = 1
      @curves.each do |curve|
        samples = curve.interpolated_samples(num_steps)
        samples.each do |sample|
          if @color_class == Color::QTR
            input_color = Color::QTR.new(curve.key, sample.input)
          elsif @color_class == Color::Gray
            input_color = Color::Gray.new(sample.input)
          else
            raise "Unexpected input color: #{@color_class.inspect}"
          end
          output_color = Color::Gray.new(sample.input).to_xyz
          set = { 'SAMPLE_ID' => sample_id }
          set.update(input_color.to_cgats)
          set.update(output_color.to_cgats)
          section << set
          sample_id += 1
        end
      end
      cgats.sections << section

      #
      # section 2: DENSITY_EXTREME_VALUES
      #

      density_extreme_values = if @color_class == Color::QTR
        #FIXME: dummy data from 'targen -d 2'
        [
          [100.00, 100.00, 100.00],
          [0.0000, 47.361, 100.00],
          [100.00, 0.0000, 79.351],
          [0.0000, 0.0000, 58.997],
          [100.00, 66.659, 0.0000],
          [0.0000, 35.601, 0.0000],
          [84.444, 0.0000, 0.0000],
          [0.0000, 0.0000, 0.0000],
        ].map do |values|
          Color::RGB.new(*values.map { |n| n.to_f / 100 })
        end
      elsif @color_class == Color::Gray
        #FIXME: dummy data from 'targen -d 0'
        [
          [0.0000],
          [37.802],
          [37.856],
          [82.218],
          [37.454],
          [80.493],
          [80.708],
          [100.00],
        ].map do |values|
          Color::Gray.new(*values.map { |n| n.to_f / 100 })
        end
      end

      section = CGATS::Section.new
      section.header = {
        'CTI1' => nil,
        'DESCRIPTOR' => 'Argyll Calibration Target chart information 1',
        'ORIGINATOR' => 'qttk',
        'CREATED' => DateTime.now.to_s,
        'DENSITY_EXTREME_VALUES' => 8,
      }
      section.data_fields = %w{INDEX} + @color_class.cgats_fields + %w{XYZ_X XYZ_Y XYZ_Z}
      index = 0
      density_extreme_values.each do |input_color|
        output_color = input_color.to_xyz
        set = { 'INDEX' => index }
        set.update(input_color.to_cgats)
        set.update(output_color.to_cgats)
        section << set
        index += 1
      end
      cgats.sections << section

      #
      # section 3: DEVICE_COMBINATION_VALUES
      #
      # (not implemented)
      #

      cgats_path.open('w') { |io| cgats.write(io) }
    end

    def to_html
      html = Builder::XmlMarkup.new(:indent => 2)
      html << to_svg
      html.ul do
        html.li("Channels: #{@channels.join(', ')}")
        html.li("Paper: #{paper_value.inspect}")
      end
      html.h3('Curve set:')
      html.table(:border => 1) do
        html.tr do
          [
            'key',
            'ink limit: density',
            'ink limit: deltaE',
            'density: min',
            'density: min (D)',
            'density: max',
            'density: max (D)',
            'density: range (D)',
          ].each { |s| html.th(s) }
        end
        @curves.each do |curve|
          html.tr do
            dmin, dmax = curve.dynamic_range
          # puts "\t" + "%3s: ink limits: density = %3s%%, deltaE = %3s%%; density: min = %3d%% (%3.2f D), max = %3d%% (%.2f D), range = %.2f D" %
            [
              curve.key.to_s,
              curve.density_limit ? ('%3d%%' % (curve.density_limit.input * 100)) : '--',
              curve.delta_e_limit ? ('%3d%%' % (curve.delta_e_limit.input * 100)) : '--',
              (dmin * 100).to_i, Math::log10(100.0 / dmin.l),
              (dmax * 100).to_i, Math::log10(100.0 / dmax.l),
              Math::log10(dmin.l / dmax.l),
            ].each { |s| html.td(s) }
          end
        end
      end
      html.target!
    end

    def to_svg(options={})
      size = options[:size] || 500
      svg = Builder::XmlMarkup.new(:indent => 2)
      svg.svg(:xmlns => 'http://www.w3.org/2000/svg', :version => '1.1') do
        svg.g(:width => size, :height => size) do
          svg.g(:stroke => 'blue') do
            svg.rect(:x => 0, :y => 0, :width => size, :height => size, :fill => 'none', :'stroke-width' => 1)
            svg.line(:x1 => 0, :y1 => size, :x2 => size, :y2 => 0, :'stroke-width' => 0.5)
          end
          @curves.each do |curve|

            # draw individual samples
            curve.samples.each do |sample|
              svg.circle(:cx => size * sample.input, :cy => size * (1 - sample.output), :r => 2, :stroke => 'none', :fill => "rgb(#{Color::Gray.new(sample.output).to_rgb.to_a.join(',')})")
              if sample.error && sample.error > 0.05
                svg.circle(:cx => size * sample.input, :cy => size * (1 - sample.output), :r => 2 + (sample.error * 10), :stroke => 'red', :fill => 'none')
              end
            end

            # draw interpolated curve
            samples = curve.interpolated_samples(size).map do |sample|
              [size * sample.input, size * (1 - sample.output)]
            end
            svg.g(:fill => 'none', :stroke => 'green', :'stroke-width' => 1) do
              svg.polyline(:points => samples.map { |pt| pt.join(',') }.join(' '))
            end

            # draw marker for ink limit (density)
            if (limit = curve.density_limit)
              x, y = size * limit.input, size * (1 - limit.output)
              svg.g(:stroke => 'black', :'stroke-width' => 2) do
                svg.line(:x1 => x, :y1 => y + 8, :x2 => x, :y2 => y - 8)
              end
            end

            # draw marker for ink limit (delta E)
            if (limit = curve.delta_e_limit)
              x, y = size * limit.input, size * (1 - limit.output)
              svg.g(:stroke => 'cyan', :'stroke-width' => 2) do
                svg.line(:x1 => x, :y1 => y + 8, :x2 => x, :y2 => y - 8)
              end
            end
          end
        end
      end
      svg.target!
    end

  end

end