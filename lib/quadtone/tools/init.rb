require 'quadtone'
include Quadtone

module Quadtone
  
  class InitTool < Tool
    
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :inks
    
    def parse_option(option, args)
      case option
      when '--inks', '-i'
        inks = args.shift.split(/\s+|,/)
        #FIXME: Handle negation (-LLK)
        @inks = inks.map { |ink| ink.to_sym }
      end
    end
  
    def run(name, printer)

      # - initialize
      # 
      #   - describe profile:
      #     - name (paper, channels)
      #     - printer (name)
      #     - channels to be used
      #   - create unlimited QTR target reference with defined channels
      #   - create grayscale target

      # ;;@inks = CurveSet::QTR.all_channels - [:LLK, :M]

      profile = Profile.new(
        :name => name,
        :printer => printer,
        :inks => @inks)
      profile.save!
      profile.build_targets
    end
  
  end
  
end