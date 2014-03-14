module Quadtone

  module Tools

    class Print < Tool

      attr_accessor :calibrate
      attr_accessor :printer_options
      attr_accessor :render
      attr_accessor :save_rendered
      attr_accessor :print

      def initialize
        super
        @printer_options = {}
        @render = true
        @print = true
      end

      def parse_option(option, args)
        case option
        when '--calibrate'
          @calibrate = true
        when '--save'
          @save_rendered = true
        when '--no-render'
          @render = false
          true
        when '--no-print'
          @print = false
          true
        when '--option', '--options'
          @printer_options.merge!(
            Hash[
              args.shift.split(',').map { |o| o.split('=') }
            ]
          )
        end
      end

      def run(*args)
        args.map { |p| Pathname.new(p) }.each do |image_path|
          @profile.print_file(image_path, calibrate: @calibrate, render: @render, save_rendered: @save_rendered, print: @print, printer_options: @printer_options)
        end
      end

    end

  end

end