module Quadtone

  module Tools

    class Linearize < Tool

      def run(*args)
        case (action = args.shift)
        when 'build'
          @profile.linearization_curveset.build_target
        when 'print'
          @profile.linearization_curveset.print_target
        when 'measure'
          @profile.linearization_curveset.measure_target
        when 'process'
          @profile.linearization_curveset.process_target
        else
          raise ToolUsageError, "Unknown action: #{action.inspect}"
        end
      end

    end

  end

end