module Quadtone

  module Tools

    class Target < Tool

      def run
        @profile.build_targets
      end

    end

  end

end