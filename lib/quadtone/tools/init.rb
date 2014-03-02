require 'quadtone'
include Quadtone

module Quadtone

  class InitTool < Tool

    attr_accessor :name
    attr_accessor :profile
    attr_accessor :printer
    attr_accessor :resolution
    attr_accessor :inks

    def parse_option(option, args)
      case option
      when '--profile'
        @profile = Profile.new(name: args.shift)
      when '--printer'
        @printer = Printer.new(args.shift)
      when '--resolution'
        @resolution = args.shift.to_i
      when '--inks'
        @inks = args.shift.split(/,/).map(&:to_sym)
      end
    end

    def run(*args)
      ;;pp self
      raise ToolUsageError, "Must specify profile" unless @profile
      raise ToolUsageError, "Must specify printer" unless @printer
      @profile.printer = @printer
      @profile.printer_options['Resolution'] = @resolution if @resolution
      @profile.inks = @inks if @inks
      @profile.save!
      ;;warn "Created profile #{@profile.name.inspect}"
      @profile.build_targets
    end

  end

end