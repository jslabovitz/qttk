module Quadtone

  module Tools

    class List < Tool

      def load_current_profile
        false
      end

      def run
        Profile.profile_names.each do |name|
          puts "%2s %s" % [
            (name == Profile.current_profile_name) ? '*' : '',
            name
          ]
        end
      end

    end

  end

end