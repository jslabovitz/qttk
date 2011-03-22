module Quadtone
  
  class ToolUsageError < Exception; end

  class Tool
  
    def usage
    end
  
    def description
    end
  
    def run(args)
      raise UnimplementedMethod, "Tool #{self.class} does not implement \#run"
    end
  
  end
  
end