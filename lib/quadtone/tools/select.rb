module Quadtone

  module Tools

    class Select < Tool

      def load_current_profile
        false
      end

      def run(*args)
        name = args.shift
        Profile.make_current_profile(name)
        ;;warn "Selected profile #{Profile.current_profile_name.inspect}"
      end

    end

  end

end