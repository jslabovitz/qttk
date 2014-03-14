module Color

  class Base

    include Math

    attr_accessor :components

    def self.component_names
      raise NotImplementedError, "\#component_names not implemented in #{self}"
    end

    def self.cgats_fields
      raise NotImplementedError, "\#cgats_fields not implemented in #{self}"
    end

    def self.num_components
      component_names.length
    end

    def self.colorspace_name
      self.to_s.split('::').last.downcase
    end

    def self.from_cgats(set)
      new(set.values_at(*cgats_fields))
    end

    def self.average(colors)
      avg_components = []
      errors = []
      component_names.each_with_index do |comp, i|
        avg_components << colors.map { |c| c.components[i] }.mean
        errors << colors.map { |c| c.components[i] }.standard_deviation
      end
      [new(avg_components), errors.max]
    end

    def initialize(arg)
      components = case arg
      when String
        arg =~ /^(\w+)\((.+)\)$/ or raise "Can't initialize #{self.class}: bad color string: #{arg.inspect}"
        raise "Expected #{self.class.colorspace_name.inspect} but got #{$1.inspect}" if $1.downcase != self.class.colorspace_name
        $2.split(/,\s+/).map(&:to_f)
      when Hash
        self.class.component_names.map { |n| arg[n] }
      when Array
        arg.map(&:to_f)
      else
        raise "Can't initialize #{self.class}: unknown object: #{arg.inspect}"
      end
      raise "Can't initialize #{self.class}: too many components specified: #{components.inspect}" if components.length > self.class.num_components
      @components = [0] * self.class.num_components
      components.each_with_index { |n, i| @components[i] = n if n }
    end

    def to_s
      "#{self.class.colorspace_name}(#{@components.map { |n| '%3.1f' % n }.join(', ')})"
    end

    def to_str
      to_s
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

  end

end