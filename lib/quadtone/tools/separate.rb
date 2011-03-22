require 'quadtone'
include Quadtone

module Quadtone
  
  class SeparateTool < Tool
  
    def run(args)
      montage = nil

      quad_file = args.shift or raise ToolUsageError, "Must specify quad curves file"
    
      quad_file = Pathname.new(quad_file)

      quad = QuadCurves.from_file(quad_file)

      if args.first == '--montage'
        args.shift
        montage = true
      end

      if args.first == '--gradient'
        image_file = Pathname.new('gradient.tif')
        image = Magick::Image.new(200, 200, Magick::GradientFill.new(0, 0, 0, 200, 'white', 'black'))
      else
        image_file = Pathname.new(args.shift)
        image = Magick::Image.read(image_file).first
      end

      quad_name = quad_file.basename.sub(/#{Regexp.quote(quad_file.extname)}/, '')
      separated_image_file = image_file.basename.sub(/#{Regexp.quote(image_file.extname)}/, "--#{quad_name}.tif")

      separator = Separator.new(quad)
      separated_image = separator.separate(image)
      separated_image = separated_image.montage if montage
      ;;warn "writing #{separated_image_file}"
      separated_image.write(separated_image_file) { self.compression = Magick::ZipCompression }
    end
    
  end
  
end