require 'quadtone'
include Quadtone

module Quadtone
  
  class CharacterizeTool < Tool
      
    def self.parse_args(args)
      super
    end
  
    def run
      # - determine ink curves & limits
      # 
      #   - analyze measured target
      #     - build ink curves from samples
      #     - calculate ink limits
      #     - create chart of curves
      #     - create initial QTR profile
      #     - install as QTR curve
      
      profile = Profile.from_dir(@profile_dir)
      measured_path = profile.base_dir + 'characterization.measured.txt'
      measured_target = Target.from_cgats_file(measured_path)
      measured_curveset = CurveSet::QTR.from_samples(measured_target.samples)
      measured_curveset.write_svg_file(measured_path.with_extname('.svg'))
      measured_curveset.trim_curves!
      profile.characterization_curveset = measured_curveset
      profile.save!
      profile.install unless @no_install
    end
  
  end
  
end