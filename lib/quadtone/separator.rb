module Quadtone
  
  class Separator
  
    def initialize(curve_set)
  	  @luts = {}
  	  curve_set.curves_by_channel.each do |curve|
    		color_map = Magick::Image.new(curve.num_samples, 1) do
          self.colorspace = Magick::GRAYColorspace
  		  end
        color_map.pixel_interpolation_method = Magick::IntegerInterpolatePixel
  		  color_map.view(0, 0, curve.num_samples, 1) do |view|
      		curve.samples.each do |sample|
      		  col = (sample.input.g * (curve.num_samples - 1)).ceil
            v = ((1 - sample.output.g) * 65535).to_i
            view[0][col] = Magick::Pixel.new(v, v, v)
      		end
    		end
    		@luts[curve.key] = color_map
  		end
    	self
  	end
  
    def separate(image)
      image_list = Magick::ImageList.new
      @luts.each do |channel, lut|
        image2 = image.copy.clut_channel(lut)
        image2['Label'] = channel.to_s
    	  image_list << image2
      end
      image_list
    end
  
  end
  
end