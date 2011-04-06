require 'quadtone'
include Quadtone

module Quadtone
  
  class SeparateTool < Tool
  
    attr_accessor :montage
    attr_accessor :gradient
    
    def parse_option(option, args)
      case option
      when '--montage'
        @montage = true
      when '--gradient'
        @gradient = true
      end
    end
    
    def run(quad_file, image_file=nil)
      quad_file = Pathname.new(quad_file)
      
      quad = CurveSet::QuadFile.from_quad_file(quad_file)
      
      if @gradient
        image_file = Pathname.new('gradient.tif')
        image = Magick::Image.new(200, 200, Magick::GradientFill.new(0, 0, 0, 200, 'white', 'black'))
      else
        raise ToolUsageError, "Must specify image file (or --gradient option)" unless image_file
        image_file = Pathname.new(image_file)
        image = Magick::Image.read(image_file).first
      end

      quad_name = quad_file.basename.sub(/#{Regexp.quote(quad_file.extname)}/, '')
      separated_image_file = image_file.basename.sub(/#{Regexp.quote(image_file.extname)}/, "--#{quad_name}.tif")

      separator = Separator.new(quad)
      separated_image = separator.separate(image)
      if montage
        separated_image = separated_image.montage do
          self.frame = '2x2'
        end
      end
      ;;warn "writing #{separated_image_file}"
      separated_image.write(separated_image_file) { self.compression = Magick::ZipCompression }
    end
    
  end
  
end