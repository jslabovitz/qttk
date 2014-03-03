module Quadtone

  module Tools

    class Render < Tool

      attr_accessor :profile
      attr_accessor :gamma
      attr_accessor :grayscale
      attr_accessor :compress
      attr_accessor :page_size
      attr_accessor :resolution
      attr_accessor :desired_size

      def initialize
        super
        @compress = true
        @grayscale = true
        @resolution = 360
      end

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        when '--gamma'
          @gamma = args.shift.to_f
        when '--no-compress'
          @compress = false
          true
        when '--no-grayscale'
          @grayscale = false
          true
        when '--page-size'
          @page_size = args.shift
        when '--resolution'
          @resolution = args.shift.to_i
        when '--size'
          size = args.shift.split('x')
          @desired_size = HashStruct.new(width: size[0].to_f.in, height: size[1].to_f.in)
        end
      end

      def run(*args)
        page_size = @profile.printer.page_size(@page_size)

        @desired_size ||= HashStruct.new(width: page_size.imageable_width, height: page_size.imageable_height)

        if @desired_size.width > page_size.imageable_width || desired_size.height > page_size.imageable_height
          raise "Image too large for page size (#{page_size.name})"
        end

        # Scale measurements to specified resolution

        resolution_scale = resolution / 72.0

        @desired_size.width *= resolution_scale
        @desired_size.height *= resolution_scale

        page_size.width *= resolution_scale
        page_size.height *= resolution_scale
        page_size.imageable_width *= resolution_scale
        page_size.imageable_height *= resolution_scale
        page_size.margin.left *= resolution_scale
        page_size.margin.right *= resolution_scale
        page_size.margin.top *= resolution_scale
        page_size.margin.bottom *= resolution_scale

        # Render provided files

        args.map { |p| Pathname.new(p) }.each do |input_path|

          # Read from input file
          ;;warn "#{input_path}:"
          image = Magick::ImageList.new(input_path).first
          ;;warn "\t" + "Original image size: #{image.columns}x#{image.rows}"

          # Delete profiles
          ;;warn "\t" + "Deleting profiles"
          image.delete_profile('*')

          # Change to grayscale
          if @grayscale
            ;;warn "\t" + "Changing to grayscale"
            image = image.quantize(2 ** 16, Magick::GRAYColorspace)
          end

          # Apply gamma
          if @gamma
            ;;warn "\t" + "Applying gamma #{@gamma}"
            image = image.gamma_correct(@gamma)
          end

          # Rotate to portrait mode if necessary
          if (image.columns.to_f / image.rows) > (page_size.width / page_size.height)
            ;;warn "\t" + "Rotating"
            image.rotate!(90)
          end

          # Scale to desired size
          scale = [
            desired_size.width / image.columns,
            desired_size.height / image.rows
          ].min
          image.resize!(scale)
          ;;warn "\t" + "Scaled image size by #{(scale*100).to_i}% to #{image.columns}x#{image.rows}"

          # Extend borders to center image within page, minus margins
          image = image.extent(
            page_size.width,
            page_size.height,
            -(page_size.width - image.columns) / 2,
            -(page_size.height - image.rows) / 2)
          ;;warn "\t" + "Extended image size to #{image.columns}x#{image.rows}"
          # image.crop!(page_size.margin.left, page_size.margin.top, page_size.imageable_width, page_size.imageable_height)

          ;;warn "\t" + "Final image size: #{image.columns}x#{image.rows}"

          # Write to output file
          params = []
          params << [desired_size.width, desired_size.height].map { |n| '%.2f' % (n.to_f / resolution_scale / 72) }.join('x')
          params << page_size.name
          params << "@#{@resolution}"
          params << "g#{@gamma}" if @gamma
          output_path = input_path.with_extname(".out-#{params.join('-')}.tif")
          ;;warn "\t" + "Writing image to #{output_path}"
          if @compress
            image.write(output_path) { self.compression = Magick::ZipCompression }
          else
            image.write(output_path)
          end
        end
      end

    end

  end

end