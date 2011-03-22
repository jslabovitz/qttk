require 'quadtone'
include Quadtone

module Quadtone
  
  class ProfileTool < Tool
  
    def run(args)

      options = {}

      while args.first && args.first[0] == '-'
        case (option = args.shift)
        when '--no-install'
          options[:no_install] = true
        else
          raise ToolUsageError, "Unknown option: #{option}"
        end
      end

      profile_name = args.shift or raise ToolUsageError, "Must specify profile name"

      printer = (args.shift || ENV['PRINTER']) or raise ToolUsageError, "Must specify printer, or set in $PRINTER environment variable"

      def wait_for_file(path, prompt)
        until path.exist?
          STDERR.puts
          STDERR.puts "[waiting for #{path}]"
          STDERR.print "#{prompt} [press return] "
          STDIN.gets
        end
      end

      # - initialize
      # 
      #   - describe profile:
      #     - name (paper, channels)
      #     - printer (name)
      #     - channels to be used

      profile = Profile.new(profile_name, printer)

      base_dir = Pathname.new('data') + profile.printer + profile.name
      base_dir.mkpath
      base_dir.chdir

      # - determine ink curves & limits
      # 
      #   - create unlimited QTR target reference with defined channels
      #   - print QTR target in QTR calibration mode @ 100%, then measure target
      #   - analyze measured target
      #     - build ink curves from samples
      #     - calculate ink limits
      #     - create chart of curves

      qtr_unlimited_name = 'qtr-unlimited'

      qtr_unlimited_reference_path = Pathname.new(qtr_unlimited_name + '.reference.txt')
      qtr_unlimited_measured_path = Pathname.new(qtr_unlimited_name + '.measured.txt')

      unless qtr_unlimited_reference_path.exist?
        qtr_unlimited_reference_curveset = CurveSet::QTR.new(CurveSet::QTR.all_channels - [:LLK, :M])
        qtr_unlimited_reference_curveset.generate
        # qtr_unlimited_reference_target = Target.new(17 - 1)   # tabloid size (11x17), for 17" roll paper, less margins
        qtr_unlimited_reference_target = Target.new
        oversample = 3
        steps = qtr_unlimited_reference_target.max_samples / (qtr_unlimited_reference_curveset.num_channels * oversample)
        qtr_unlimited_reference_curveset.fill_target(qtr_unlimited_reference_target, 
          :steps => steps, 
          :oversample => oversample)
        qtr_unlimited_reference_target.write_image_file(qtr_unlimited_reference_path.with_extname('.tif'))
        qtr_unlimited_reference_target.write_cgats_file(qtr_unlimited_reference_path)
      end

      wait_for_file(qtr_unlimited_measured_path, "print & measure target for #{qtr_unlimited_reference_path} -- save data to #{qtr_unlimited_measured_path}")

      qtr_unlimited_measured_target = Target.from_cgats_file(qtr_unlimited_measured_path)
      qtr_unlimited_measured_curveset = CurveSet::QTR.from_samples(qtr_unlimited_measured_target.samples)
      qtr_unlimited_measured_curveset.write_svg_file(qtr_unlimited_measured_path.with_extname('.svg'), :normalize => true)
      qtr_unlimited_measured_curveset.trim_curves!

      # - determine ink curves
      # 
      #   - create limited QTR target with defined channels
      #   - print QTR target in QTR calibration mode @ 100%, then measure target
      #   - analyze measured target
      #     - build ink curves from samples
      #     - create chart of curves
      #     - create initial QTR profile
      #     - install as QTR curve

      qtr_limited_name = 'qtr-limited'

      qtr_limited_reference_path = Pathname.new(qtr_limited_name + '.reference.txt')
      qtr_limited_measured_path = Pathname.new(qtr_limited_name + '.measured.txt')

      unless qtr_limited_reference_path.exist?
        qtr_limited_reference_curveset = CurveSet::QTR.new(qtr_unlimited_measured_curveset.channels)
        qtr_limited_reference_curveset.generate
        # qtr_limited_target = Target.new(17 - 1)   # tabloid size (11x17), for 17" roll paper, less margins
        qtr_limited_target = Target.new
        oversample = 3
        steps = qtr_limited_target.max_samples / (qtr_limited_reference_curveset.num_channels * oversample)
        qtr_limited_reference_curveset.fill_target(qtr_limited_target, 
          :steps => steps, 
          :oversample => oversample, 
          :limits => qtr_unlimited_measured_curveset.limits)
        qtr_limited_target.write_image_file(qtr_limited_reference_path.with_extname('.tif'))
        qtr_limited_target.write_cgats_file(qtr_limited_reference_path)
      end

      wait_for_file(qtr_limited_measured_path, "print & measure target for #{qtr_limited_reference_path} -- save data to #{qtr_limited_measured_path}")

      qtr_limited_measured_target = Target.from_cgats_file(qtr_limited_measured_path)
      qtr_limited_measured_curveset = CurveSet::QTR.from_samples(qtr_limited_measured_target.samples)
      qtr_limited_measured_curveset.write_svg_file(qtr_limited_measured_path.with_extname('.svg'), :normalize => true)

      profile.unlimited_qtr_curveset = qtr_unlimited_measured_curveset
      profile.limited_qtr_curveset = qtr_limited_measured_curveset
      profile.install unless options[:no_install]

      # - linearize grayscale
      # 
      #   - create grayscale target
      #   - print grayscale target image with QTR curve, then measure target
      #   - analyze measured target
      #     - build grayscale curve from samples
      #     - add linearization to profile
      #     - create final QTR profile
      #     - install as QTR curve
      #     - create chart of curves

      grayscale_name = 'grayscale'

      grayscale_reference_path = Pathname.new(grayscale_name + '.reference.txt')
      grayscale_measured_path = Pathname.new(grayscale_name + '.measured.txt')

      unless grayscale_reference_path.exist?
        grayscale_reference_curveset = CurveSet::Grayscale.new
        grayscale_reference_curveset.generate
        grayscale_target = Target.new
        grayscale_reference_curveset.fill_target(grayscale_target, :steps => 51, :oversample => 4)
        grayscale_target.write_image_file(grayscale_reference_path.with_extname('.tif'))
        grayscale_target.write_cgats_file(grayscale_reference_path)
      end

      wait_for_file(grayscale_measured_path, "print & measure target #{grayscale_reference_path} -- save data to #{grayscale_measured_path}")

      grayscale_measured_target = Target.from_cgats_file(grayscale_measured_path)
      grayscale_measured_curveset = CurveSet::Grayscale.from_samples(grayscale_measured_target.samples)
      grayscale_measured_curveset.write_svg_file(grayscale_measured_path.with_extname('.svg'), :normalize => true)

      profile.grayscale_curveset = grayscale_measured_curveset
      profile.install unless options[:no_install]
    
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
      # test_grayscale_measured_curveset.write_svg_file(test_grayscale_measured_path.with_extname('.svg'), :normalize => true)

      #FIXME: See above
    end
  
  end
  
end