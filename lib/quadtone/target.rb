module Quadtone

  class Target

    attr_accessor :base_dir
    attr_accessor :channels
    attr_accessor :type
    attr_accessor :name
    attr_accessor :ink_limits
    attr_accessor :samples

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
      raise "Base directory must be specified" unless @base_dir
      raise "Channels must be specified" unless @channels
      raise "Type must be specified" unless @type
      raise "Name must be specified" unless @name
    end

    def build
      ;;warn "Making target for channels #{@channels.inspect}"
      cleanup_files(:all)

      resolution = 360
      page_size = HashStruct.new(width: 8, height: 10.5)
      # total_patches = 42
      ;;total_patches = 14
      patches_per_row = 14
      total_rows = total_patches / patches_per_row
      row_height = 165
      target_size = [
        ((total_rows + 1) * row_height).to_f / resolution,
        page_size.height,
      ].map { |n| (n * 25.4).to_i }.join('x')

      image_list = Magick::ImageList.new
      @channels.each do |channel|
        sub_path = base_file(channel)
        sub_image_path = image_file(channel)
        ;;warn "Making target #{sub_path.inspect} at #{sub_image_path}"
        Quadtone.run('targen',
          # '-v',                 # Verbose mode [optional level 1..N]
          '-d', 0,              # generate grayscale target
          '-e', 0,              # White test patches (default 4)
          '-B', 0,              # Black test patches (default 4 Grey/RGB, else 0)
          '-s', total_patches,  # Single channel steps (default grey 50, color 0)
          sub_path)
        Quadtone.run('printtarg',
          # '-v',                 # Verbose mode [optional level 1..N]
          '-a', 1.45,           # Scale patch size and spacers by factor (e.g. 0.857 or 1.5 etc.)
          '-r',                 # Don't randomize patch location
          '-i', 'i1',           # set instrument to EyeOne (FIXME: make configurable)
          '-t', resolution,     # generate 16-bit TIFF @ 360 ppi
          '-m', 0,              # Set a page margin in mm (default 6.0 mm)
          '-L',                 # Suppress any left paper clip border
          '-p', target_size,    # Select page size
          sub_path)
        image = Magick::Image.read(sub_image_path).first
        # image.background_color = 'transparent'
        # image = image.transparent('white')
        case @type
        when :characterization
          if @ink_limits && (limit = @ink_limits[channel]) && limit != 1
            ;;warn "\t" + "#{channel.to_s.upcase}: Applying limit of #{limit}"
            levels = [1.0 - limit, 1.0].map { |n| n * Magick::QuantumRange }
            image = image.levelize_channel(*levels)
          end
          # calculate a black RGB pixel for this channel in QTR calibration mode
          black_qtr = Color::QTR.new(channel: channel, value: 0)
          black_rgb = black_qtr.to_rgb
          ;;warn "\t" + "#{channel.to_s.upcase}: Colorizing to #{black_rgb}"
          image = image.colorize(1, 0, 1, black_rgb.to_pixel)
        end
        image_list << image
      end

      if @type == :linearization || @type == :test

        width = (page_size.width * resolution).to_i - image_list.first.columns
        height = page_size.height * resolution

        ;;width = (page_size.width / 2) * resolution

        linear_scale_height = 1 * resolution
        radial_scale_height = (height - linear_scale_height) / 2
        sample_image_height = (height - linear_scale_height) / 2

        test_images = Magick::ImageList.new
        test_images << linear_gradation_scale_image([width, linear_scale_height])
        test_images << radial_gradation_scale_image([width, radial_scale_height])
        test_images << sample_image([width, sample_image_height])
        image_list << test_images.append(true)
      end

      # ;;warn "montaging images"
      # image_list = image_list.montage do
      #   self.geometry = Magick::Geometry.new(page_size.width * resolution, page_size.height * resolution)
      #   self.tile = Magick::Geometry.new(image_list.length, 1)
      # end

      # ;;warn "writing target image"
      # image_list.write(image_file) do
      #   self.depth = (@type == :characterization) ? 8 : 16
      #   self.compression = Magick::ZipCompression
      # end

      ;;warn "writing target image"
      image_list.append(false).write(image_file) do
        self.depth = (@type == :characterization) ? 8 : 16
        self.compression = Magick::ZipCompression
      end

    end

    def linear_gradation_scale_image(size)
      ;;warn "\t" + "generating linear gradation scale of size #{size.inspect}"
      bounds = Magick::Rectangle.new(*size, 0, 0)
      image1 = Magick::Image.new(bounds.width, bounds.height/2, Magick::GradientFill.new(0, 0, 0, bounds.height/2, 'white', 'black'))
      image2 = image1.posterize(21)
      image3 = image1.posterize(256)
      ilist = Magick::ImageList.new
      ilist << image1
      ilist << image2
      ilist << image3
      ilist.append(true)
    end

    def radial_gradation_scale_image(size)
      ;;warn "\t" + "generating radial gradation scale of size #{size.inspect}"
      bounds = Magick::Rectangle.new(*size, 0, 0)
      image1 = Magick::Image.new(bounds.width, bounds.height/2, Magick::GradientFill.new(bounds.width/2, bounds.height/2, bounds.width/2, bounds.height/2, 'black', 'white'))
      image2 = image1.posterize(21).flip
      ilist = Magick::ImageList.new
      ilist << image1
      ilist << image2
      ilist.append(true)
    end

    def sample_image(size)
      ;;warn "\t" + "generating sample image of size #{size.inspect}"
      bounds = Magick::Rectangle.new(*size, 0, 0)
      ilist = Magick::ImageList.new(Pathname.new(ENV['HOME']) + 'Desktop' + '121213b.01.tif')
      ilist.first.resize_to_fill(*size)
    end

    def measure(options={})
      options = HashStruct.new(options)
      channels_to_measure = options.channels || @channels
      channels_to_measure.each_with_index do |channel, i|
        measure_channel(channel, options.merge(disable_calibration: i > 0))
      end
    end

    def measure_channel(channel, options=HashStruct.new)
      options = HashStruct.new(options)
      if options.remeasure
        pass = options.remeasure
      else
        pass = ti2_files(channel).length
      end
      base = base_file(channel, pass)
      FileUtils.cp(ti2_file(channel), base.with_extname('.ti2')) unless options.remeasure
      ;;warn "Measuring target #{base.inspect}"
      Quadtone.run('chartread',
        # '-v',                             # Verbose mode [optional level 1..N]
        '-p',                             # Measure patch by patch rather than strip
        '-n',                             # Don't save spectral information (default saves spectral)
        '-l',                             # Save CIE as D50 L*a*b* rather than XYZ
        options.disable_calibration ? '-N' : nil, # Disable initial calibration of instrument if possible
        options.remeasure ? '-r' : nil,   # Resume reading partly read chart
        base)
    end

    def read
      ;;warn "reading samples for #{@channels.join(', ')} from CGATS files"
      @samples = {}
      @channels.each do |channel|
        samples = {}
        ti3_files(channel).map do |file|
          ;;warn "reading #{file}"
          cgats = CGATS.new_from_file(file)
          cgats.sections.first.data.each do |set|
            id = set['SAMPLE_LOC'].gsub(/"/, '')
            samples[id] ||= []
            samples[id] << Sample.new(input: Color::Gray.from_cgats(set), output: Color::Lab.from_cgats(set))
          end
        end
        @samples[channel] = samples.map do |id, samples|
          cc = ClusterCalculator.new(samples: samples, max_clusters: samples.length > 2 ? 2 : 1)
          cc.cluster!
          clusters = cc.clusters.sort_by(&:size).reverse
          # ;;warn "Clusters:"
          # clusters.each do |cluster|
          #   warn "\t" + cluster.center.to_s
          #   cluster.samples.each do |sample|
          #     warn "\t\t" + "#{sample.to_s}"
          #   end
          # end
          # ;;
          cluster = clusters.shift
          raise "Too much spread" if cluster.samples.length < 2 && samples.length > 2
          unless clusters.empty?
            warn "Dropped #{clusters.length} out of range sample(s) at patch #{channel}-#{id}"
          end
          output = cluster.center
          Sample.new(input: samples.first.input, output: output, label: "#{channel}-#{id}")
        end
      end
    end

    # private

    def base_file(channel=nil, n=nil)
      @base_dir + (@name.to_s + (channel ? "-#{channel}" : '') + (n ? "-#{n}" : ''))
    end

    def ti1_file(channel)
      base_file(channel).with_extname('.ti1')
    end

    def ti2_file(channel, n=nil)
      base_file(channel, n).with_extname('.ti2')
    end

    def ti3_file(channel, n=nil)
      base_file(channel, n).with_extname('.ti3')
    end

    def image_file(channel=nil)
      base_file(channel).with_extname('.tif')
    end

    def values_file(channel=nil)
      base_file(channel).with_extname('.txt')
    end

    def ti_files
      Pathname.glob(base_file.with_extname('*.ti[123]'))
    end

    def ti2_files(channel)
      Pathname.glob(base_file(channel).with_extname('*.ti2'))
    end

    def ti3_files(channel)
      Pathname.glob(base_file(channel).with_extname('*.ti3'))
    end

    def image_files
      Pathname.glob(base_file.with_extname('*.tif'))
    end

    def cleanup_files(files)
      ;;warn "deleting files: #{files.inspect}"
      files = [files].flatten
      until files.empty?
        file = files.shift
        case file
        when :all
          files << :ti
          files += image_files
        when :ti
          files += ti_files
        when Pathname
          if file.exist?
            # ;;warn "\t" + file
            file.unlink
          end
        else
          raise "Unknown file to cleanup: #{file}"
        end
      end
    end

  end

end