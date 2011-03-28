require 'quadtone'
include Quadtone

module Quadtone
  
  class LinearizeTool < Tool
  
    def self.parse_args(args)
      super
    end
  
    def run
      # - linearize grayscale
      # 
      #   - print grayscale target image with QTR curve, then measure target
      #   - analyze measured target
      #     - build grayscale curve from samples
      #     - add linearization to profile
      #     - create final QTR profile
      #     - install as QTR curve
      #     - create chart of curves

      profile = Profile.from_dir(@profile_dir)
      measured_path = profile.base_dir + 'linearization.measured.txt'
      measured_target = Target.from_cgats_file(measured_path)
      measured_curveset = CurveSet::Grayscale.from_samples(measured_target.samples)
      measured_curveset.write_svg_file(measured_path.with_extname('.svg'))
      profile.linearization_curveset = measured_curveset
      profile.save!
      profile.install unless @no_install
    end
  
  end
  
end