require 'quadtone'
include Quadtone

module Quadtone

  class ProfileTool < Tool

    attr_accessor :profile
    attr_accessor :no_install

    def parse_global_option(option, args)
      case option
      when '--profile'
        @profile = Profile.load(args.shift)
      when '--no-install'
        @no_install = true
      end
    end

    def run
      @profile.write_qtr_profile
      @profile.install unless @no_install
    end

  end

end