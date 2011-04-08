require 'quadtone'
include Quadtone

module Quadtone
  
  class ChartTool < Tool
      
    def run(*measurement_files)
      measurement_files.map { |p| Pathname.new(p) }.each do |path|
        target = Target.from_cgats_file(path)
        mode = target.color_mode
        if mode == Color::QTR
          curveset = CurveSet::QTR.from_samples(target.samples)
        elsif mode == Color::GrayScale
          curveset = CurveSet::Grayscale.from_samples(target.samples)
        else
          raise "Don't know how to chart target in color mode #{mode.inspect}"
        end
        svg_path = path.with_extname('.svg')
        ;;warn "writing SVG file to #{svg_path}"
        curveset.write_svg_file(svg_path)
      end
    end
  
  end
  
end