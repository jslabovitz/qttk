module Quadtone

  class ToolUsageError < Exception; end

  class Tool

    def self.process_args(args, tools)
      begin
        name = args.shift or raise ToolUsageError, "No subcommand specified"
        klass = tools[name] or raise ToolUsageError, "Unknown subcommand specified"
        tool = klass.new
        while args.first && args.first[0] == '-'
          option = args.shift
          tool.parse_global_option(option, args) or tool.parse_option(option, args) or raise ToolUsageError, "Unknown option: #{option}"
        end
        tool.run(*args)
      rescue ToolUsageError => e
        warn e
        exit 1
      end
    end

    def parse_global_option(option, args)
      # case option
      # when '--profile'
      #   @profile_name = args.shift or raise ToolUsageError, "Must specify profile name"
      # end
    end

    def parse_option(option, args)
      # overridden by subclass
    end

  end

end