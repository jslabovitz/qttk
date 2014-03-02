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
      when '--calibrate'
        @calibrate = true
      when '--option', '--options'
        @options.merge!(
          Hash[
            args.shift.split(',').map { |o| o.split('=') }
          ]
        )
      end
    end

    def run(*args)
      profile = Profile.from_dir(@profile_dir)
      options = @options.dup
      options['ColorModel'] = @calibrate ? 'QTCAL' : 'QTRIP16'
      args.map { |p| Pathname.new(p) }.each do |image_path|
        profile.print_image(image_path, options)
      end
    end

  end

end