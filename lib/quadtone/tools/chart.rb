require 'quadtone'
include Quadtone

module Quadtone
  
  class ChartTool < Tool
      
    def run
      profile = Profile.from_dir(@profile_dir)
      if profile.characterization_curveset
        svg_path = profile.characterization_measured_path.with_extname('.svg')
        ;;warn "writing SVG file to #{svg_path}"
        profile.characterization_curveset.write_svg_file(svg_path)
      end
      if profile.linearization_curveset
        svg_path = profile.linearization_measured_path.with_extname('.svg')
        ;;warn "writing SVG file to #{svg_path}"
        profile.linearization_curveset.write_svg_file(svg_path)
      end
    end
  
  end
  
end