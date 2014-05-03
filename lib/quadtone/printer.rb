module Quadtone

  class Printer

    ImportantOptions = %i{
      MediaType
      Resolution
      ripBlack
      ripSpeed
      stpDither
    }

    attr_accessor :name
    attr_accessor :options
    attr_accessor :attributes
    attr_accessor :inks

    def initialize(name)
      @name = name
      @cups_ppd = CupsPPD.new(@name, nil)
      @options = Hash[
        @cups_ppd.options.map { |o| [o.delete(:keyword).to_sym, HashStruct.new(o)] }
      ]
      @attributes = Hash[
        @cups_ppd.attributes.map { |a| [a.delete(:name).to_sym, HashStruct.new(a)] }
      ]
      @cups_printer = CupsPrinter.new(@name)
      get_inks
    end

    def quadtone?
      @attributes[:Manufacturer].value == 'QuadToneRIP'
    end

    def get_inks
      # FIXME: It would be nice to get this path programmatically.
      ppd_file = Pathname.new("/etc/cups/ppd/#{@name}.ppd")
      ppd_file.readlines.each do |line|
        if line =~ /^\*%Inks\s*(.*?)\s*$/
          @inks = $1.split(/,/).map(&:downcase).map(&:to_sym)
          break
        end
      end
    end

    def page_size(name=nil)
      name ||= @cups_ppd.attribute('DefaultPageSize').first[:value]
      page_size = @cups_ppd.page_size(name) or raise "Can't determine page size #{name.inspect}"
      size = HashStruct.new(page_size)
      # change 'length' to 'height', or else there are problems with Hash#length
      size[:height] = size.delete(:length)
      size = HashStruct.new(size)
      size.imageable_width = size.margin.right - size.margin.left
      size.imageable_height = size.margin.top - size.margin.bottom
      size
    end

    def default_options
      Hash[
        @options.map do |name, option|
          [name, option.default_choice]
        end
      ]
    end

    def show_attributes
      puts "Attributes:"
      max_field_length = @attributes.keys.map(&:length).max
      @attributes.sort_by { |name, info| name }.each do |name, attribute|
        puts "\t" + "%#{max_field_length}s: %s%s" % [
          name,
          attribute.value.inspect,
          attribute.spec.empty? ? '' : " [#{attribute.spec.inspect}]"
        ]
      end
    end

    def show_options
      puts "Options:"
      max_field_length = @options.keys.map(&:length).max
      @options.sort_by { |name, option| name }.each do |name, option|
        puts "\t" + "%#{max_field_length}s: %s [%s]" % [
          name,
          option.default_choice.inspect,
          (option.choices.map { |o| o.choice } - [option.default_choice]).map { |o| o.inspect }.join(', ')
        ]
      end
    end

    def show_inks
      puts "Inks:"
      puts "\t" + @inks.map { |ink| ink.to_s.upcase }.join(', ')
    end

    def print_file(path, options)
      warn "Printing #{path}"
      warn "Options:"
      options.each do |key, value|
        warn "\t" + "%10s: %s" % [key, value]
      end
      @cups_printer.print_file(path, options)
    end

  end

end