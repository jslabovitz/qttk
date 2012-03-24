require 'quadtone'
include Quadtone

module Quadtone
  
  class TargetTool < Tool
    
    def run
      profile = Profile.from_dir(@profile_dir)
      profile.build_targets
    end
  
  end
  
end