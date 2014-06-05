module Quadtone

  class Separator

    attr_accessor :luts

    def initialize(curve_set)
  	  @luts = {}
  	  curve_set.curves.each do |curve|
    		color_map = Magick::Image.new(curve.num_samples, 1) do
          self.colorspace = Magick::GRAYColorspace
  		  end
        color_map.pixel_interpolation_method = Magick::IntegerInterpolatePixel
  		  color_map.view(0, 0, curve.num_samples, 1) do |view|
          curve.samples.each_with_index do |sample, x|
            value = ((1 - sample.output.value) * 65535).to_i
            view[0][x] = Magick::Pixel.new(value, value, value)
      		end
    		end
        @luts[curve.channel] = color_map
  		end
  	end

    def separate(image)
      images = {}
      @luts.each do |channel, lut|
        image2 = image.copy.clut_channel(lut)
        image2['Label'] = channel.to_s.upcase
        images[channel] = image2
      end
      images
    end

  end

end