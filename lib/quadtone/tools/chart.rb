require 'quadtone'
include Quadtone

module Quadtone
  
  class ChartTool < Tool
    
    attr_accessor :open
    
    def parse_option(option, args)
      case option
      when '--open', '-o'
        @open = true
      end
    end
    
    def run
      profile = Profile.from_dir(@profile_dir)
      html_path = Pathname.new('profile.html')
      html_path.open('w') { |io| io.write(profile.to_html) }
      ;;puts "Saved HTML to #{html_path}"
      system 'open', html_path if @open
    end
  
  end
  
end