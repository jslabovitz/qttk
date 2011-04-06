require 'quadtone'
include Quadtone

module Quadtone
  
  class ChartTool < Tool
      
    def run
      profile = Profile.from_dir(@profile_dir)
      if profile.characterization_curveset
        profile.characterization_curveset.write_svg_file(profile.characterization_measured_path.with_extname('.svg'))
      else
        warn "No characterization curveset to chart."
      end
      if profile.linearization_curveset
        profile.linearization_curveset.write_svg_file(profile.linearization_measured_path.with_extname('.svg'))
      else
        warn "No linearization curveset to chart."
      end
    end
  
  end
  
end