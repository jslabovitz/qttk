module Quadtone

  module Tools

    class Test < Tool

      def run(*args)
        case (action = args.shift)
        when 'build'
          @profile.test_curveset.build_target
        when 'print'
          @profile.test_curveset.print_target
        when 'measure'
          @profile.test_curveset.measure_target
        when 'process'
          @profile.test_curveset.process_target
        else
          raise ToolUsageError, "Unknown action: #{action.inspect}"
        end
      end

    end

  end

end