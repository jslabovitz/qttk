module Quadtone

  module Tools

    class Target < Tool

      attr_accessor :profile

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        end
      end

      def run
        @profile.build_targets
      end

    end

  end

end