module Quadtone

  module Tools

    class Separate < Tool

      attr_accessor :profile
      attr_accessor :montage
      attr_accessor :gradient

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        when '--montage'
          @montage = true
        when '--gradient'
          @gradient = true
        end
      end

      def run(image_file=nil)

        if @gradient
          image_file = Pathname.new('gradient.tif')
          image = Magick::Image.new(200, 200, Magick::GradientFill.new(0, 0, 0, 200, 'white', 'black'))
        else
          raise ToolUsageError, "Must specify image file (or --gradient option)" unless image_file
          image_file = Pathname.new(image_file)
          image = Magick::Image.read(image_file).first
        end

        quad = CurveSet.from_quad_file(@profile.quad_file_path)
        separator = Separator.new(quad)
        separated_image = separator.separate(image)
        if montage
          separated_image = separated_image.montage do
            self.frame = '2x2'
          end
        end

        separated_image_file = image_file.with_extname(".#{@profile.name}.tif")
        ;;warn "writing #{separated_image_file}"
        separated_image.write(separated_image_file) { self.compression = Magick::ZipCompression }
      end

    end

  end

end