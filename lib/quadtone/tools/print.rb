module Quadtone

  module Tools

    class Print < Tool

      attr_accessor :calibrate
      attr_accessor :printer_options

      def initialize
        super
        @printer_options = {}
      end

      def parse_option(option, args)
        case option
        when '--calibrate'
          @calibrate = true
        when '--option', '--options'
          @printer_options.merge!(
            Hash[
              args.shift.split(',').map { |o| o.split('=') }
            ]
          )
        end
      end

      def run(*args)
        args.map { |p| Path.new(p) }.each do |image_path|
          @profile.print_file(image_path, calibrate: @calibrate, printer_options: @printer_options)
        end
      end

    end

  end

end