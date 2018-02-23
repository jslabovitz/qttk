module Quadtone

  module Tools

    class Render < Tool

      attr_accessor :rotate
      attr_accessor :resolution
      attr_accessor :page_size
      attr_accessor :desired_size

      def parse_option(option, args)
        case option
        when '--rotate'
          @rotate = true
        when '--resolution'
          @resolution = args.shift.to_f
        when '--page-size'
          @page_size = @profile.printer.page_size(args.shift)
        when '--desired-size'
          width, height = args.shift.split('x').map(&:to_f)
          @desired_size = HashStruct.new(width: width, height: height)
        end
      end

      def run(*args)
        options = {}
        options.merge!(rotate: @rotate) if @rotate
        options.merge!(resolution: @resolution) if @resolution
        options.merge!(page_size: @page_size) if @page_size
        options.merge!(desired_size: @desired_size) if @desired_size
        renderer = Renderer.new(options)
        args.map { |p| Pathname.new(p) }.each do |input_path|
          output_paths = renderer.render(input_path)
          ;;warn "\t" + "Wrote rendered file to #{output_paths.join(', ')}"
        end
      end

    end

  end

end