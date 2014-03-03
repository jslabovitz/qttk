module Quadtone

  module Tools

    class Measure < Tool

      attr_accessor :profile
      attr_accessor :characterization
      attr_accessor :linearization

      def parse_option(option, args)
        case option
        when '--profile'
          @profile = Profile.load(args.shift)
        when '--characterization'
          @characterization = true
        when '--linearization'
          @linearization = true
        end
      end

      def run(*args)
        @profile.measure_targets(characterization: @characterization, linearization: @linearization)
      end

    end

  end

end