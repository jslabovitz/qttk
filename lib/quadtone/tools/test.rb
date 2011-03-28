require 'quadtone'
include Quadtone

module Quadtone
  
  class ProfileTool < Tool
  
    attr_accessor :no_install
    
    def self.parse_args(args)
      options = super
      # process_options(args) do |option, args|
      #   case option
      #   when '--no-install'
      #     options[:no_install] = true
      #   else
      #     raise ToolUsageError, "Unknown option: #{option}"
      #   end
      # end
      options
    end
  
    def run
      ;;warn "Not yet implemented"
      # - test linearization
      # 
      #   - print grayscale target image with QTR curve, then measure target
      #   - analyze measured target
      #     - build grayscale curve from samples
      #     - test for linear response
      #     - show dMin/dMax, Lab curve
      # 
      #   - store each test with timestamp
      # 
      #   - chart scale over time (with multiple tests)
      #     - graph differences between values
      #     - graph average dE
      #       - see: http://cias.rit.edu/~gravure/tt/pdf/pc/TT5_Fred01.pdf (p. 34)

      # test_grayscale_name = 'test-grayscale'
      # 
      # test_grayscale_measured_path = Pathname.new(test_grayscale_name + '.measured.txt')
      # 
      # wait_for_file(test_grayscale_measured_path, "print & measure target #{grayscale_reference_path} -- save data to #{test_grayscale_measured_path}")
      # 
      # test_grayscale_measured_target = Target.from_cgats_file(test_grayscale_measured_path)
      # test_grayscale_measured_curveset = CurveSet::Grayscale.from_samples(test_grayscale_measured_target.samples)
      # test_grayscale_measured_curveset.write_svg_file(test_grayscale_measured_path.with_extname('.svg'))

      #FIXME: See above
    end
  
  end
  
end