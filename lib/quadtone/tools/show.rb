module Quadtone

  module Tools

    class Show < Tool

      attr_accessor :profile

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        end
      end

      def run
        @profile.show
      end

    end

  end

end