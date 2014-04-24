module Quadtone

  module Tools

    class Init < Tool

      def load_profile
        false
      end

      def run(*args)
        get_printer
        get_printer_options
        get_inks
        get_medium
        profile = Profile.new(printer: @printer, printer_options: @printer_options, inks: @inks, medium: @medium)
        profile.save
        ;;warn "Created profile #{profile.name.inspect}"
      end

      def get_printer
        printers = CupsPrinter.get_all_printer_names.map { |n| Printer.new(n) }.select(&:quadtone?)
        @printer = prompt('Printer', printers, printers[0]) { |p| p.name }
      end

      def get_printer_options
        @printer_options = {}
        @printer.options.each do |name, option|
          if Printer::ImportantOptions.include?(name)
            choices = option.choices.map { |c| c.choice }
            default = option.choices.find { |c| c.choice == option.default_choice }
            @printer_options[name] = prompt(name, choices, default)
          end
        end
      end

      def get_medium
        media = [
          'Epson Velvet Fine Art',
          'Epson Ultra Premium Presentation',
          'Epson Premium Presentation',
          'Epson Premium Luster',
          'Hahnemuhle Bamboo',
          'Southworth Antique Laid',
          'Crane Museo',
        ]
        @medium = prompt('Media', media, media[0])
      end

      def get_inks
        @inks = prompt('Inks', @printer.inks, @printer.inks.join(','))
        @inks = [@inks] unless @inks.kind_of?(Array)
      end

      def prompt(label, values, default=nil, &block)
        choices = {}
        values.each_with_index { |value, i| choices[i + 1] = value }
        STDERR.puts
        STDERR.puts "#{label}:"
        choices.each { |i, value| STDERR.puts '%2d. %s' % [i, block_given? ? yield(value) : value] }
        STDERR.print "Choice" + (default ? " [#{block_given? ? yield(default) : default}]" : '') + "? "
        selections = STDIN.gets.chomp
        if selections.empty?
          default
        else
          selections = selections.split(',').map(&:to_i)
          case selections.length
          when 0
            default
          when 1
            choices[selections.first]
          else
            selections.map { |s| choices[s] }
          end
        end
      end

    end

  end

end