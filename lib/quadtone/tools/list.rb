module Quadtone

  module Tools

    class List < Tool

      def load_profile
        false
      end

      def run
        Profile.profile_names.each { |name| puts name }
      end

    end

  end

end