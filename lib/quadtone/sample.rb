module Quadtone

  class Sample

    attr_accessor :input
    attr_accessor :output
    attr_accessor :error

    def initialize(params={})
      params.each { |key, value| send("#{key}=", value) }
    end

    def input_value
      @input.value
    end

    def output_value
      @output.value
    end

    def to_s
      "#{input} / #{output}"
    end

  end

end