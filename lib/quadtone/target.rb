module Quadtone
  
  class Target
    
    attr_accessor :samples
      
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
    
    def initialize
      @samples = []
    end    
    
    def read_cgats_file!(cgats_file)
      @samples = CGATS.new_from_file(cgats_file).data.map { |set| Sample.from_cgats_data(set) }
    end
    
  end
  
end