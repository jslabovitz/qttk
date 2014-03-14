module Quadtone

  module Tools

    class Edit < Tool

      def run
        # editor = ENV['EDITOR'] or raise "Can't determine editor"
        editor = 'subl'
        Quadtone.run(editor,
          '--wait',
          @profile.qtr_profile_path)
        @profile = Profile.load_current_profile
        @profile.check
        @profile.save
        @profile.show
      end

    end

  end

end