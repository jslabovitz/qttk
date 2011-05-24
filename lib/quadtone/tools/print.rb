require 'quadtone'
include Quadtone

module Quadtone
  
  class PrintTool < Tool
  
    attr_accessor :calibrate
    attr_accessor :options
    
    def initialize
      super
      @options = {}
    end
    
    def parse_option(option, args)
      case option
      when '--calibrate', '-c'
        @calibrate = true
      when '--show-options'
        @show_options = true
      when '--option', '--options', '-o'
        @options.merge!(
          Hash[
            args.shift.split(',').map { |o| o.split('=') }
          ]
        )
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      options = @options.dup
      options['ColorModel'] = @calibrate ? 'QTCAL' : 'QTRIP16'
      profile.dump_printer_options if @show_options
      image_files.map { |p| Pathname.new(p) }.each do |image_path|
        profile.print_image(image_path, options)
      end
    end
    
  end
  
end