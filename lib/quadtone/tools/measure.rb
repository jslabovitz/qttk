require 'quadtone'
include Quadtone

module Quadtone
  
  class MeasureTool < Tool
    
    attr_accessor :characterization
    attr_accessor :linearization
    
    def initialize
      super
    end
    
    def parse_option(option, args)
      case option
      when '--characterization', '-c'
        @characterization = true
      when '--linearization', '-l'
        @linearization = true
      end
    end
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      options = {}
      options[:characterization] = true if @characterization
      options[:linearization] = true if @linearization
      profile.measure_targets(options)
    end
    
  end
  
end