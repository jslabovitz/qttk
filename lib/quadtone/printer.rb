module Quadtone

  class Printer

    attr_accessor :name
    attr_accessor :options
    attr_accessor :attributes

    def initialize(name)
      @name = name
      @cups_ppd = CupsPPD.new(@name, nil)
      @options = @cups_ppd.options.map { |o| HashStruct.new(o) }
      @attributes = @cups_ppd.attributes.map { |a| HashStruct.new(a) }
      @cups_printer = CupsPrinter.new(@name)
    end

    def inks
      # FIXME: It would be nice to get this path programmatically.
      ppd_file = Pathname.new("/etc/cups/ppd/#{@name}.ppd")
      ink_description = ppd_file.readlines.find { |l| l =~ /^\*%Inks\s*(.*?)\s*$/ } or raise "Can't find inks description for printer #{@name.inspect}"
      ink_description.chomp.split(/\s+/, 2).last.split(/,/).map(&:to_sym)
    end

    def page_size(name=nil)
      name ||= @cups_ppd.attribute('DefaultPageSize').first[:value]
      size = HashStruct.new(@cups_ppd.page_size(name))
      # change 'length' to 'height', or else there are problems with Hash#length
      size[:height] = size.delete(:length)
      size = HashStruct.new(size)
      size.imageable_width = (size.margin.right - size.margin.left).pt
      size.imageable_height = (size.margin.top - size.margin.bottom).pt
      size
    end

    def default_options
      Hash[
        @options.map do |option|
          [option.keyword, option.default_choice]
        end
      ]
    end

    def print_printer_attributes
      puts "Attributes:"
      max_field_length = @attributes.map(&:name).map(&:length).max
      @attributes.sort_by(&:name).each do |attribute|
        puts "\t" + "%#{max_field_length}s: %s%s" % [
          attribute.name,
          attribute.value.inspect,
          attribute.spec.empty? ? '' : " [#{attribute.spec.inspect}]"
        ]
      end
    end

    def print_printer_options
      puts "Options:"
      max_field_length = @options.map(&:keyword).map(&:length).max
      @options.sort_by(&:keyword).each do |option|
        puts "\t" + "%#{max_field_length}s: %s [%s]" % [
          option.keyword,
          option.default_choice.inspect,
          (option.choices.map { |o| o.choice } - [option.default_choice]).map { |o| o.inspect }.join(', ')
        ]
      end
    end

    def print_file(image_path, options)
      warn "Printing:"
      warn "\t" + image_path
      warn "Options:"
      options.each do |key, value|
        warn "\t" + "%10s: %s" % [key, value.inspect]
      end
      @cups_printer.print_file(image_path, options)
    end

  end

end