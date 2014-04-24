module Quadtone

  module Tools

    class Rename < Tool

      def run(*args)
        new_name = args.shift or raise "Must specify new name"
        new_path = Profile::ProfilesDir + new_name
        @profile.dir_path.rename(new_path)
      end

    end

  end

end