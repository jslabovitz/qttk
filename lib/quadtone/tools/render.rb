module Quadtone

  module Tools

    class Render < Tool

      attr_accessor :printer_options
      attr_accessor :rotate
      attr_accessor :resolution

      def initialize
        super
        @printer_options = {}
        @rotate = false
        @resolution = false
      end

      def parse_option(option, args)
        case option
        when '--rotate'
          @rotate = true
        when '--resolution'
          @resolution = args.shift.to_f
        when '--page-size'
          @page_size = args.shift
        when '--option', '--options'
          @printer_options.merge!(
            Hash[
              args.shift.split(',').map { |o| o.split('=') }
            ]
          )
        end
      end

      def run(*args)
        page_size = @profile.printer.page_size(@page_size)
        renderer = Renderer.new(grayscale: true, page_size: page_size, rotate: @rotate, resolution: @resolution)
        args.map { |p| Pathname.new(p) }.each do |input_path|
          output_path = renderer.render(input_path)
          ;;warn "\t" + "Wrote rendered file to #{output_path}"
        end
      end

    end

  end

end