require 'quadtone'
include Quadtone

module Quadtone
  
  class ProfileTool < Tool
      
    def self.parse_args(args)
      super
    end
  
    def run
      profile = Profile.from_dir(@profile_dir)
      profile.write_qtr_profile
      profile.install unless @no_install
    end
  
  end
  
end