require 'quadtone'
include Quadtone

module Quadtone
  
  class TargetTool < Tool
    
    def run
      profile = Profile.from_dir(@profile_dir)
      options = {}
      profile.build_targets(options)
    end
  
  end
  
end