module Quadtone

  module Tools

    class Render < Tool

      attr_accessor :rotate
      attr_accessor :resolution

      def parse_option(option, args)
        case option
        when '--rotate'
          @rotate = true
        when '--resolution'
          @resolution = args.shift.to_f
        when '--page-size'
          @page_size = @profile.printer.page_size(args.shift)
        end
      end

      def run(*args)
        options = {}
        options.merge!(page_size: @page_size) if @page_size
        options.merge!(rotate: @rotate) if @rotate
        options.merge!(resolution: @resolution) if @resolution
        renderer = Renderer.new(options)
        args.map { |p| Pathname.new(p) }.each do |input_path|
          output_paths = renderer.render(input_path)
          ;;warn "\t" + "Wrote rendered file to #{output_paths.join(', ')}"
        end
      end

    end

  end

end