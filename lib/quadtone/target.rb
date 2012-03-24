module Quadtone
  
  class Target
    
    attr_accessor :samples
      
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
    
    def self.build(name, inks, color_class, dest_dir='.')
      dest_dir = Pathname.new(dest_dir)
      image_list = Magick::ImageList.new
      tile_width = tile_height = nil
      inks.each do |component|
        sub_name = "#{name}-#{component}"
        ;;warn "Making target #{sub_name.inspect}"
        run('targen',
          '-d', 0,              # generate grayscale target
          dest_dir + sub_name)
        run('printtarg',
          '-i', 'i1',           # set instrument to EyeOne (FIXME: make configurable)
          '-b',                 # force B&W spacers
          '-t',                 # generate 8-bit TIFF
          '-R', 1,              # start random seed at 1
          '-p', '38x279.4',     # page size just big enough to hold this target (1.5" x 11")
          '-L',                 # suppress paper clip border
          '-M', 0,              # zero margin
      		dest_dir + sub_name)
        image = Magick::Image.read(dest_dir + "#{sub_name}.tif").first
        tile_width ||= image.columns
        tile_height ||= image.rows
        if color_class == Color::QTR
          # get the RGB values for a black pixel for this channel in QTR calibration mode
        	rgb = Color::QTR.new(component, 0).to_rgb.map { |c| (c / 255.0) * Magick::QuantumRange }
          image = image.colorize(1, 0, 1, Magick::Pixel.new(*rgb))
        end
        image_list << image
      end
      image_list = image_list.montage do
        self.geometry = Magick::Geometry.new(tile_width, tile_height)
        self.tile = Magick::Geometry.new(image_list.length, 1)
      end
      final_name = [name, color_class.to_s.split(/::/).last].join('-')
      image_list.write(dest_dir + "#{final_name}.tif")
      inks.each do |ink|
        Pathname.new(dest_dir + "#{name}-#{ink}.tif").unlink
      end
    end
    
    def initialize
      @samples = []
    end
    
    def read_cgats_file!(cgats_file)
      @samples = CGATS.new_from_file(cgats_file).data.map { |set| Sample.from_cgats_data(set) }
    end
    
  end
  
end