require 'quadtone'
include Quadtone

module Quadtone

  class InitTool < Tool

    attr_accessor :printer
    attr_accessor :resolution

    def parse_option(option, args)
      case option
      when '--printer'
        @printer = Printer.new(args.shift)
      when '--resolution'
        @resolution = args.shift.to_i
      end
    end

    def run(*args)
      name = args.shift or raise ToolUsageError, "Must specify profile name"
      raise ToolUsageError, "Must specify printer" unless @printer
      profile = Profile.new(name: name, printer: @printer)
      profile.setup_default_inks
      profile.printer_options['Resolution'] = @resolution if @resolution
      profile.save
      ;;warn "Created profile #{profile.name.inspect}"
    end

  end

end