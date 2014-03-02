require 'quadtone'
include Quadtone

module Quadtone

  class PrinterOptionsTool < Tool

    attr_accessor :printer

    def parse_option(option, args)
      case option
      when '--printer'
        @printer = Printer.new(args.shift)
      end
    end

    def run(*args)
      if @printer
        printer = @printer
      elsif @profile_dir
        profile = Profile.from_dir(@profile_dir)
        printer = profile.printer
      else
        raise ToolUsageError, "Must specify either printer or profile"
      end
      # printer.print_printer_attributes
      printer.print_printer_options
    end

  end

end