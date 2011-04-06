module Quadtone
  
  class ToolUsageError < Exception; end

  class Tool
    
    attr_accessor :profile_dir
    attr_accessor :no_install
    
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
      case option
      when '--profile-dir', '-p'
        dir = args.shift or raise "Must specify profile directory"
        @profile_dir = Pathname.new(dir)
      when '--no-install'
        @no_install = true
      end
    end
    
    def initialize
      @profile_dir = Pathname.new('.')
    end
    
    def run(args)
      raise UnimplementedMethod, "Tool #{self.class} does not implement \#run"
    end
  
    def wait_for_file(path, prompt)
      until path.exist?
        STDERR.puts
        STDERR.puts "[waiting for #{path}]"
        STDERR.print "#{prompt} [press return] "
        STDIN.gets
      end
    end
    
  end
  
end