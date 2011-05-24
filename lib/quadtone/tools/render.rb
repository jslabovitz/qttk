require 'quadtone'
include Quadtone

module Quadtone
  
  class RenderTool < Tool
  
    attr_accessor :gamma
    attr_accessor :compress
    attr_accessor :page_size
    attr_accessor :resolution
    attr_accessor :desired_size
    
    def initialize
      super
      @compress = true
      @resolution = 360
    end
    
    def parse_option(option, args)
      case option
      when '--gamma', '-g'
        @gamma = args.shift.to_f
      when '--no-compress'
        @compress = false
        true
      when '--page-size'
        @page_size = args.shift
      when '--resolution'
        @resolution = args.shift.to_i
      when '--size'
        size = args.shift.split('x')
        @desired_size = { :width => size[0].to_f.in, :height => size[1].to_f.in }
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      page_size = profile.page_size(@page_size)
      
      @desired_size ||= { :width => page_size[:imageable_width], :height => page_size[:imageable_height] }
      
      if @desired_size[:width] > page_size[:imageable_width] || desired_size[:height] > page_size[:imageable_height]
        raise "Image too large for page size (#{page_size[:name]})"
      end
      
      # Scale measurements to specified resolution
      
      resolution_scale = resolution.to_f / 72
      
      desired_width = @desired_size[:width] * resolution_scale
      desired_height = @desired_size[:height] * resolution_scale
      
      page_width = page_size[:width] * resolution_scale
      page_height = page_size[:length] * resolution_scale
      
      page_imageable_width = page_size[:imageable_width] * resolution_scale
      page_imageable_height = page_size[:imageable_height] * resolution_scale
      
      page_margin_left = page_size[:margin][:left] * resolution_scale
      page_margin_right = (page_size[:width] - page_size[:margin][:left]) * resolution_scale
      page_margin_top = (page_size[:length] - page_size[:margin][:top]) * resolution_scale
      page_margin_bottom = page_size[:margin][:bottom] * resolution_scale
      
      # Render provided files
      
      image_files.map { |p| Pathname.new(p) }.each do |input_path|
        
        # Read from input file
        ;;warn "#{input_path}:"
        image = Magick::ImageList.new(input_path).first
        ;;warn "\t" + "Original image size: #{image.columns}x#{image.rows}"
        
        # Delete profiles
        ;;warn "\t" + "Deleting profiles"
        image.delete_profile('*')
        
        # Change to grayscale
        ;;warn "\t" + "Changing to grayscale"
        image = image.quantize(2 ** 16, Magick::GRAYColorspace)
        
        # Apply gamma
        if @gamma
          ;;warn "\t" + "Applying gamma #{@gamma}"
          image = image.gamma_correct(@gamma)
        end
        
        # Rotate to portrait mode if necessary
        image.rotate!(90, '>')
        
        # Scale to desired size
        h_scale = desired_width.to_f / image.columns
        v_scale = desired_height.to_f / image.rows
        scale = [h_scale, v_scale].min
        warn "\t" + "Scaling by #{(scale*100).to_i}%"
        image.resize!(scale)
        ;;warn "\t" + "Scaled image size: #{image.columns}x#{image.rows}"
        
        # Extend borders to center image within page
        ##, minus margins
        image = image.extent(
          page_width,
          page_height,
          -(page_width - image.columns) / 2, 
          -(page_height - image.rows) / 2)
        image.crop!(page_margin_left, page_margin_top, page_imageable_width, page_imageable_height)

        ;;warn "\t" + "Final image size: #{image.columns}x#{image.rows}"
        
        # Write to output file
        params = []
        params << [desired_width, desired_height].map { |n| '%.2f' % (n.to_f / resolution_scale / 72) }.join('x')
        params << page_size[:name]
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