require 'quadtone'
include Quadtone

module Quadtone
  
  class MeasureTool < Tool
  
    attr_accessor :spot
    
    def initialize
      super
    end
    
    def parse_option(option, args)
      case option
      when '--spot', '-s'
        @spot = true
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      profile.measure(:spot => @spot)
    end
    
  end
  
end