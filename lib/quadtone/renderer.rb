module Quadtone

  class Renderer

    attr_accessor :gamma
    attr_accessor :rotate
    attr_accessor :compress
    attr_accessor :page_size
    attr_accessor :resolution
    attr_accessor :desired_size

    def initialize(params={})
      @compress = true
      @resolution = 720
      params.each { |k, v| send("#{k}=", v) }
    end

    def render(input_path)
      @input_path = input_path

      raise "Page size required" unless @page_size

      # Scale measurements to specified resolution

      @page_size.width = (@page_size.width / 72.0 * @resolution).to_i
      @page_size.height = (@page_size.height / 72.0 * @resolution).to_i
      @page_size.imageable_width = (@page_size.imageable_width / 72.0 * @resolution).to_i
      @page_size.imageable_height = (@page_size.imageable_height / 72.0 * @resolution).to_i
      @page_size.margin.left = (@page_size.margin.left / 72.0 * @resolution).to_i
      @page_size.margin.right = (@page_size.margin.right / 72.0 * @resolution).to_i
      @page_size.margin.top = (@page_size.margin.top / 72.0 * @resolution).to_i
      @page_size.margin.bottom = (@page_size.margin.bottom / 72.0 * @resolution).to_i

      if @desired_size
        @desired_size.width = (@desired_size.width * @resolution).to_i
        @desired_size.height = (@desired_size.height * @resolution).to_i
        if @desired_size.width > @page_size.imageable_width || @desired_size.height > @page_size.imageable_height
          raise "Image too large for page size (#{@page_size.name})"
        end
      else
        @desired_size = HashStruct.new(width: @page_size.imageable_width, height: @page_size.imageable_height)
      end

      ;;warn "Reading #{@input_path} @ #{@resolution}dpi"
      r = @resolution  # have to alias to avoid referring to ImageList object
      image_list = Magick::ImageList.new(@input_path) {
        self.density = r
      }
      output_paths = []
      image_list.each_with_index do |image, image_index|
        @current_image = image
        @current_image_index = image_index
        ;;warn "\t" + "Processing sub-image \##{@current_image_index}"
        show_info
        delete_profiles
        convert_to_16bit
        apply_gamma
        rotate
        resize
        extend_to_page
        crop_to_imageable_area
        show_info
        output_paths << write_to_file
      end
      output_paths
    end

    def output_path
      params = []
      params << "#{@desired_size.width}x#{@desired_size.height}"
      params << @page_size.name
      params << "@#{@resolution}"
      params << "g#{@gamma}" if @gamma
      @input_path.with_extname(".out-#{params.join('-')}.#{@current_image_index}.png")
    end

    def show_info
      ;;warn "\t\t" + @current_image.inspect
    end

    def delete_profiles
      ;;warn "\t\t" + "Deleting profiles"
      @current_image.delete_profile('*')
    end

    def convert_to_16bit
      ;;warn "\t\t" + "Changing to grayscale"
      @current_image = @current_image.quantize(2 ** 16, Magick::GRAYColorspace)
    end

    def apply_gamma
      if @gamma
        ;;warn "\t\t" + "Applying gamma #{@gamma}"
        @current_image = @current_image.gamma_correct(@gamma)
      end
    end

    def rotate
      if @rotate
        ;;warn "\t\t" + "Rotating #{@rotate}°"
        @current_image.rotate!(@rotate)
      elsif (@current_image.columns.to_f / @current_image.rows) > (@page_size.width.to_f / @page_size.height)
        ;;warn "\t\t" + "Auto-rotating 90°"
        @current_image.rotate!(90)
      end
    end

    def resize
      ;;warn "\t\t" + "Resizing to desired size"
      @current_image.resize_to_fit!(@desired_size.width, @desired_size.height)
    end

    def extend_to_page
      ;;warn "\t\t" + "Extending canvas to page area"
      @current_image = @current_image.extent(
        @page_size.width,
        @page_size.height,
        -(@page_size.width - @current_image.columns) / 2,
        -(@page_size.height - @current_image.rows) / 2)
    end

    def crop_to_imageable_area
      x, y, w, h = @page_size.margin.left, @page_size.height - @page_size.margin.top, @page_size.imageable_width, @page_size.imageable_height
      ;;warn "\t\t" + "Cropping to imageable area (x,y = #{x},#{y}, w,h = #{w},#{h})"
      @current_image.crop!(x, y, w, h)
    end

    def write_to_file
      path = output_path
      ;;warn "\t\t" + "Writing image to #{path}"
      @current_image.write(path) do
        self.compression = @compress ? Magick::ZipCompression : Magick::NoCompression
      end
      path
    end

  end

end