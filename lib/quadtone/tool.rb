module Quadtone

  class ToolUsageError < Exception; end

  class Tool

    attr_accessor :printer

    def self.process_args(args)
      begin
        name = args.shift or raise ToolUsageError, "No subcommand specified"
        klass_name = 'Quadtone::Tools::' + name.split('-').map { |p| p.capitalize }.join
        klass = Kernel.const_get(klass_name) or raise ToolUsageError, "Unknown subcommand specified: #{name.inspect} (#{klass_name})"
        tool = klass.new
        tool.process_environment
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

    def process_environment
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