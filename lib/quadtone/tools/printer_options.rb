module Quadtone

  module Tools

    class PrinterOptions < Tool

      attr_accessor :profile
      attr_accessor :printer
      attr_accessor :show_attributes

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        when '--printer'
          @printer = Printer.new(args.shift)
        when '--attributes'
          @show_attributes = true
        end
      end

      def run(*args)
        if @printer
          printer = @printer
        elsif @profile
          printer = @profile.printer
        else
          raise ToolUsageError, "Must specify either printer or profile"
        end
        printer.print_printer_attributes if @show_attributes
        printer.print_printer_options
      end

    end

  end

end