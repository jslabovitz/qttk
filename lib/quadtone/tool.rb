module Quadtone

  class ToolUsageError < Exception; end

  class Tool

    attr_accessor :profile
    attr_accessor :verbose

    def self.process_args(args)
      begin
        name = args.shift or raise ToolUsageError, "No subcommand specified"
        klass_name = 'Quadtone::Tools::' + name.split('-').map { |p| p.capitalize }.join
        begin
          klass = Kernel.const_get(klass_name)
          raise NameError unless klass.respond_to?(:process_args)
        rescue NameError => e
          raise ToolUsageError, "Unknown subcommand specified: #{name.inspect} (#{klass_name})"
        end
        tool = klass.new
        tool.process_environment
        tool.load_profile
        while args.first && args.first[0] == '-'
          option = args.shift
          tool.parse_global_option(option, args) or tool.parse_option(option, args) or raise ToolUsageError, "Unknown option for #{name.inspect} tool: #{option}"
        end
        tool.run(*args)
      rescue ToolUsageError => e
        warn e
        exit 1
      end
    end

    def process_environment
      if (profile_name = ENV['PROFILE'])
        @profile = Profile.load(profile_name)
      end
    end

    def parse_global_option(option, args)
      case option
      when '--verbose'
        @verbose = true
      when '--profile'
        @profile = Profile.load(args.shift)
      end
    end

    def parse_option(option, args)
      # overridden by subclass
    end

    # subclass can override this to avoid requirement of profile being set

    def load_profile
      raise ToolUsageError, "No profile set" unless @profile
    end

  end

end