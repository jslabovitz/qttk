require 'quadtone'
include Quadtone

module Quadtone
  
  class PrintTool < Tool
  
    attr_accessor :calibrate
    attr_accessor :media
    
    def parse_option(option, args)
      case option
      when '--calibrate', '-c'
        @calibrate = true
      when '--media', '-m'
        @media = args.shift
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      options = {}
      options['ColorModel'] = 'QTCAL' if @calibrate
      options['Media'] = @media if @media
      image_files.each { |p| Pathname.new(p) }.each do |image_path|
        profile.print_image(image_path, options)
      end
    end
    
  end
  
end