require 'quadtone'
include Quadtone

module Quadtone
  
  class InitTool < Tool
    
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :inks
    attr_accessor :resolution
    
    def initialize
      #FIXME: Use cupsffi
      @printer = `lpstat -d`.chomp.sub(/system default destination: /, '')
    end
    
    def parse_option(option, args)
      case option
      when '--inks', '-i'
        inks = args.shift.split(/\s+|,/)
        #FIXME: Handle negation (-LLK)
        @inks = inks.map { |ink| ink.to_sym }
      when '--printer', '-p'
        @printer = args.shift
      when '--resolution', '-r'
        @resolution = args.shift
      end
    end
  
    def run(name)
      profile = Profile.new(
        :name => name,
        :printer => @printer,
        :printer_options => {
          'Resolution' => @resolution,
        },
        :inks => @inks,
      )
      profile.save!
    end
  
  end
  
end