require 'quadtone'
include Quadtone

module Quadtone

  class InstallTool < Tool

    attr_accessor :profile

    def parse_global_option(option, args)
      case option
      when '--profile'
        @profile = Profile.load(args.shift)
      end
    end

    def run
      @profile.install
    end

  end

end