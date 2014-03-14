module Quadtone

  module Tools

    class Check < Tool

      def run
        @profile.check
        ;;warn "Profile checks out okay."
      end

    end

  end

end