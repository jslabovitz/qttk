require 'quadtone'
include Quadtone

module Quadtone

  class TargetTool < Tool

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