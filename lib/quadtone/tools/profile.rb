require 'quadtone'
include Quadtone

module Quadtone

  class ProfileTool < Tool

    attr_accessor :no_install

    def parse_global_option(option, args)
      case option
      when '--no-install'
        @no_install = true
      end
    end

    def run
      profile = Profile.from_dir(@profile_dir)
      profile.write_qtr_profile
      profile.install unless @no_install
    end

  end

end