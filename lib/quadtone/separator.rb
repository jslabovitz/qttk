module Quadtone
  
  class Separator
  
    def initialize(quad)
      @quad = quad
  	  @luts = {}
  	  quad.channels.each do |channel|
    		curve = quad[channel] or next
    		color_map = Magick::Image.new(curve.length, 1) do
          self.colorspace = Magick::GRAYColorspace
  		  end
        color_map.pixel_interpolation_method = Magick::IntegerInterpolatePixel
  		  color_map.view(0, 0, curve.length, 1) do |view|
      		curve.each_with_index do |v, x|
            v = (1 - v) * 65535
            view[0][curve.length - 1 - x] = Magick::Pixel.new(v, v, v)
      		end
    		end
    		@luts[channel] = color_map
  		end
    	self
  	end
  
    def separate(image)
      image_list = Magick::ImageList.new
      @quad.channels.each do |channel|
        lut = @luts[channel] or next
        image2 = image.copy.clut_channel(lut)
        image2['Label'] = channel.to_s
    	  image_list << image2
      end
      image_list
    end
  
  end
  
end