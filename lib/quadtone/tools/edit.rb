module Quadtone

  module Tools

    class Edit < Tool

      def run
        editor = ENV['EDITOR'] or raise "Can't determine editor"
        system(editor,
          '--wait',
          @profile.qtr_profile_path.to_s)
        @profile = Profile.load(@profile.name)
        @profile.check
        @profile.save
        @profile.show
      end

    end

  end

end