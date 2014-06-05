module Quadtone

  module Tools

    class Separate < Tool

      attr_accessor :montage
      attr_accessor :gradient
      attr_accessor :save_luts

      def parse_option(option, args)
        case option
        when '--montage'
          @montage = true
        when '--gradient'
          @gradient = true
        when '--save-luts'
          @save_luts = true
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

        quad = QuadFile.new(@profile)
        separator = Separator.new(quad.curve_set)
        images = separator.separate(image)

        if @montage
          image_list = Magick::ImageList.new
          image_copy = image.copy
          image_copy['Label'] = 'original'
          image_list << image_copy
          image_list += images.values
          separated_image = image_list.montage do
            self.frame = '2x2'
            self.geometry = '300x300'
          end
          separated_image_file = image_file.with_extname(".#{@profile.name}.sep.tif")
          ;;warn "writing montaged separated file to #{separated_image_file}"
          separated_image.write(separated_image_file) { self.compression = Magick::ZipCompression }
        else
          images.each do |channel, separated_image|
            separated_image_file = image_file.with_extname(".#{@profile.name}.sep-#{channel}.tif")
            ;;warn "writing channel #{channel} of separated file to #{separated_image_file}"
            separated_image.write(separated_image_file) { self.compression = Magick::ZipCompression }
          end
        end

        if @save_luts
          separator.luts.each do |channel, lut_image|
            lut_file = image_file.with_extname(".#{@profile.name}.lut-#{channel}.tif")
            ;;warn "writing LUT image to #{lut_file}"
            lut_image.write(lut_file) { self.compression = Magick::ZipCompression }
          end
        end
      end

    end

  end

end