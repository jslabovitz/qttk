module Quadtone
  
  class Sample
  
    attr_accessor :input
    attr_accessor :output
    attr_accessor :error
        
    def initialize(input, output, error=nil)
      @input = input
      @output = output
      @error = error
    end
  
  end
  
end