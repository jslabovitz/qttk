module Quadtone
  
  class ToolUsageError < Exception; end

  class Tool
    
    attr_accessor :profile_dir
    
    def self.process_options(args, &block)
      while args.first && args.first[0] == '-'
        yield(args.shift, args)
      end
    end
    
    def self.parse_args(args)
      options = {}
      process_options(args) do |option, args|
        case option
        when '--profile-dir', '-p'
          options[:profile_dir] = Pathname.new(args.shift) or raise "Must specify profile directory"
        else
          raise ToolUsageError, "Unknown option: #{option}"
        end
      end
      options
    end
    
    def initialize(options={})
      options.each do |key, value|
        begin
          method("#{key}=").call(value)
        rescue NameError => e
          raise "Unknown option for #{self.class}: #{key.inspect}"
        end
      end
    end
    
    def run
      raise UnimplementedMethod, "Tool #{self.class} does not implement \#run"
    end
  
  end
  
end