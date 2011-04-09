require 'quadtone'
include Quadtone

module Quadtone
  
  class PrintTool < Tool
  
    attr_accessor :calibrate
    attr_accessor :resolution
    attr_accessor :fit_to_page
    attr_accessor :media
    
    def parse_option(option, args)
      case option
      when '--calibrate', '-c'
        @calibrate = true
      when '--resolution', '-r'
        @resolution = args.shift
      when '--fit-to-page', '-f'
        @fit_to_page = true
      when '--media', '-m'
        @media = args.shift
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      ;;profile.dump_printer_options
      options = {}
      options['Resolution'] = @resolution if @resolution
      options['ColorModel'] = 'QTCAL' if @calibrate
      options['Media'] = @media if @calibrate
      image_files.each { |p| Pathname.new(p) }.each do |image_path|
        profile.print_image(image_path, options)
      end
    end
    
  end
  
end