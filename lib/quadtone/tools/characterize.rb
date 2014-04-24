module Quadtone

  module Tools

    class Characterize < Tool

      def parse_option(option, args)
        case option
        when '--force'
          @force = true
        end
      end

      def run(*args)
        case (action = args.shift)
        when 'build'
          @profile.characterization_curveset.build_target
        when 'print'
          @profile.characterization_curveset.print_target
        when 'measure'
          @profile.characterization_curveset.measure_target(force: @force)
        when 'process'
          @profile.characterization_curveset.process_target
        when 'chart'
          @profile.characterization_curveset.chart_target
        else
          raise ToolUsageError, "Unknown action: #{action.inspect}"
        end
      end

    end

  end

end