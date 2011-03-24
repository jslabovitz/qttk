require 'quadtone'
include Quadtone

module Quadtone
  
  class DumpTool < Tool
  
    def run(args)
      path = Pathname.new(args.shift)
      
      tmp_dir = Pathname.new('/tmp')
      
      curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(path).samples)
      curveset.write_svg_file(tmp_dir + path.with_extname('1.svg').basename)
      ;;curveset.dump

      curveset.curves[0] = curveset.curves.first.resample(11)
      curveset.write_svg_file(tmp_dir + path.with_extname('2.svg').basename)
      ;;curveset.dump
      
      ;;warn curveset.curves.first.output_density_scale(21).map { |d| (d * 100).to_i }
      
    end
    
  end
  
end