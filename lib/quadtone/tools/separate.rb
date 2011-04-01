require 'quadtone'
include Quadtone

module Quadtone
  
  class SeparateTool < Tool
  
    attr_accessor :quad_file
    attr_accessor :montage
    attr_accessor :gradient
    attr_accessor :image_file
    
    def self.parse_args(args)
      options = super
      options[:quad_file] = args.shift or raise ToolUsageError, "Must specify quad curves file"
      process_options(args) do |option, args|
        case option
        when '--montage'
          options[:montage] = true
        when '--gradient'
          options[:gradient] = true
        else
          raise ToolUsageError, "Unknown option: #{option}"
        end
      end
      unless options[:gradient]
        options[:image_file] = args.shift or raise ToolUsageError, "Must specify image file (or --gradient option)"
      end
      options
    end
    
    def run
      @quad_file = Pathname.new(@quad_file)
      
      quad = CurveSet::QuadFile.from_quad_file(@quad_file)
      if @gradient
        image_file = Pathname.new('gradient.tif')
        image = Magick::Image.new(200, 200, Magick::GradientFill.new(0, 0, 0, 200, 'white', 'black'))
      else
        @image_file = Pathname.new(@image_file)
        image = Magick::Image.read(@image_file).first
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