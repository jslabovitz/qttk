require 'quadtone'
include Quadtone

module Quadtone
  
  class DumpTool < Tool
  
    def run(curveset_file)
      curveset_file = Pathname.new(curveset_file)
      tmp_dir = Pathname.new('/tmp')
      curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(curveset_file).samples)
      curveset.write_svg_file(tmp_dir + curveset_file.with_extname('.svg').basename)
    end
    
  end
  
end