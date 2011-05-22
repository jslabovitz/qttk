require 'quadtone'
include Quadtone

module Quadtone
  
  class TargetTool < Tool
    
    attr_accessor :randomize
    attr_accessor :oversample
    attr_accessor :steps
    
    def parse_option(option, args)
      case option
      when '--randomize'
        @randomize = true
      when '--oversample'
        @oversample = args.shift.to_i
      when '--steps'
        @steps = args.shift.to_i
      end
    end
    
    def run
      profile = Profile.from_dir(@profile_dir)
      options = {}
      options[:randomize] = @randomize if @randomize
      options[:oversample] = @oversample if @oversample
      options[:steps] = @steps if @steps
      profile.build_targets(options)
    end
  
  end
  
end