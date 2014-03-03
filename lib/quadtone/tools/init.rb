module Quadtone

  module Tools

    class Init < Tool

      attr_accessor :printer

      def load_current_profile
        false
      end

      def parse_option(option, args)
        case option
        when '--printer'
          @printer = Printer.new(args.shift)
        end
      end

      def run(*args)
        name = args.shift or raise ToolUsageError, "Must specify profile name"
        raise ToolUsageError, "Must specify printer" unless @printer
        profile = Profile.new(name: name, printer: @printer)
        profile.setup_defaults
        profile.save
        profile.make_current_profile
        ;;warn "Created profile #{profile.name.inspect}"
      end

    end

  end

end