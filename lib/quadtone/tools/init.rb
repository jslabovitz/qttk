require 'quadtone'
include Quadtone

module Quadtone
  
  class InitTool < Tool
  
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :inks
    
    def self.parse_args(args)
      options = super
      process_options(args) do |option, args|
        case option
        when '--inks', '-i'
          inks = args.shift.split(/\s+|,/)
          #FIXME: Handle negation (-LLK)
          options[:inks] = inks.map { |ink| ink.to_sym }
        else
          raise ToolUsageError, "Unknown option: #{option}"
        end
      end
      options[:name] = args.shift or raise ToolUsageError, "Must specify profile name"
      options[:printer] = (args.shift || ENV['PRINTER']) or raise ToolUsageError, "Must specify printer, or set in $PRINTER environment variable"
      options
    end
  
    def run

      # - initialize
      # 
      #   - describe profile:
      #     - name (paper, channels)
      #     - printer (name)
      #     - channels to be used
      #   - create unlimited QTR target reference with defined channels
      #   - create grayscale target

      ;;@inks = CurveSet::QTR.all_channels - [:LLK, :M]

      profile = Profile.new(
        :name => @name,
        :printer => @printer,
        :inks => @inks)
      profile.save!
      profile.build_characterization_target
      profile.build_linearization_target
    end
  
  end
  
end