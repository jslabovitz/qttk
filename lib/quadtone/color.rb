module Color
  
  class Base
    
    attr_accessor :components
    
    def self.component_names
      raise "\#component_names not defined in #{self}"
    end
    
    def self.num_components
      component_names.length
    end
    
    def self.from_cgats(components)
      new(components)
    end
    
    def self.average(colors, method=:mad)
      avg_components = []
      errors = []
      case method
      when :mad
        component_names.each_with_index do |comp, i|
          median, mad = colors.map { |c| c.components[i] }.median, colors.map { |c| c.components[i] }.mad
          errors << mad / median
          avg_components << median
        end
      when :stdev
        component_names.each_with_index do |comp, i|
          median, stdev = colors.map { |c| c.components[i] }.mean_stdev
          errors << stdev / mean
          avg_components << mean
        end
      else
        raise "Unknown averaging method: #{method.inspect}"
      end
      [new(*avg_components), errors.max]
    end
        
    def initialize(components)
      @components = components + ([0] * (self.class.num_components - components.length))
    end
    
    def to_cgats
      @components
    end
    
    def hash
      @components.hash
    end
    
    def eql?(other)
      @components == other.components
    end
    
    def <=>(other)
      @components <=> other.components
    end
    
    def inspect
      "<%s>" % @components.map { |v| v.to_s }.join(' ')
    end

  end
  
end