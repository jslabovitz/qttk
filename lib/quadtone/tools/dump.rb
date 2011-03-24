require 'quadtone'
include Quadtone

module Quadtone
  
  class DumpTool < Tool
  
    def run(args)
      path = Pathname.new(args.shift)
      
      tmp_dir = Pathname.new('/tmp')
      
      curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(path).samples)
      curveset.write_svg_file(tmp_dir + path.with_extname('.svg').basename)
      
    end
    
  end
  
end