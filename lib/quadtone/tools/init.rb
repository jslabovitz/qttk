require 'quadtone'
include Quadtone

module Quadtone

  class InitTool < Tool

    attr_accessor :name
    attr_accessor :printer
    attr_accessor :resolution
    attr_accessor :inks

    def parse_option(option, args)
      case option
      when '--printer'
        @printer = args.shift
      when '--resolution'
        @resolution = args.shift
      when '--inks'
        @inks = args.shift
      end
    end

    def run(name=nil)
      raise ToolUsageError, "Must specify printer" unless @printer
      raise ToolUsageError, "Must specify profile directory" unless @profile_dir
      name = @profile_dir.basename
      printer_options = {}
      printer_options.merge!('Resolution' => @resolution) if @resolution
      profile = Profile.new(
        :name => name,
        :printer => @printer,
        :printer_options => printer_options,
        :inks => @inks ? @inks.split(/,/).map(&:to_sym) : nil)
      profile.save!
      ;;warn "Created profile #{profile.name.inspect}"
      profile.build_targets
    end

  end

end