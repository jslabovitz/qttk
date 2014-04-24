module Quadtone

  module Tools

    class PrinterOptions < Tool

      attr_accessor :printer
      attr_accessor :show_attributes

      def load_profile
        false
      end

      def parse_option(option, args)
        case option
        when '--printer'
          @printer = Printer.new(args.shift)
        when '--show-attributes'
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
        printer.show_attributes if @show_attributes
        printer.show_options
        printer.show_inks
      end

    end

  end

end