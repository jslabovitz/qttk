module Quadtone

  class Profile

    attr_accessor :name
    attr_accessor :printer
    attr_accessor :printer_options
    attr_accessor :inks
    attr_accessor :ink_limits
    attr_accessor :ink_partitions
    attr_accessor :linearization
    attr_accessor :default_ink_limit
    attr_accessor :gray_highlight
    attr_accessor :gray_shadow
    attr_accessor :gray_overlap
    attr_accessor :gray_gamma

    ProfilesDir = BaseDir + 'profiles'
    ProfileName = 'profile'
    ImportantPrinterOptions = %w{MediaType Resolution ripSpeed stpDither}

    def self.load(name)
      profile = Profile.new(name: name)
      inks_by_num = []
      profile.qtr_profile_path.readlines.each do |line|
        line.chomp!
        line.sub!(/#.*/, '')
        line.strip!
        next if line.empty?
        key, value = line.split('=', 2)
        case key
        when 'PRINTER'
          profile.printer = value
        when 'PRINTER_OPTIONS'
          profile.printer_options = Hash[ value.split(',').map { |o| o.split('=') } ]
        when 'GRAPH_CURVE'
          # ignore
        when 'N_OF_INKS'
          # ignore
        when 'DEFAULT_INK_LIMIT'
          profile.default_ink_limit = value.to_f / 100
        when /^LIMIT_(.+)$/
          profile.ink_limits[$1] = value.to_f / 100
        when 'N_OF_GRAY_PARTS'
          # ignore
        when /^GRAY_INK_(\d+)$/
          i = $1.to_i - 1
          partition = (profile.ink_partitions[i] ||= HashStruct.new)
          partition.ink = value.to_sym
        when /^GRAY_VAL_(\d+)$/
          i = $1.to_i - 1
          partition = (profile.ink_partitions[i] ||= HashStruct.new)
          partition.value = value.to_f / 100
        when 'GRAY_HIGHLIGHT'
          profile.gray_highlight = value.to_f / 100
        when 'GRAY_SHADOW'
          profile.gray_shadow = value.to_f / 100
        when 'GRAY_OVERLAP'
          profile.gray_overlap = value.to_f / 100
        when 'GRAY_GAMMA'
          profile.gray_gamma = value.to_f
        when 'LINEARIZE'
          profile.linearization = value.gsub('"', '').split(/\s+/).map { |v| v.to_f / 100 }
        else
          raise "Unknown key in QTR profile: #{key.inspect}"
        end
      end
      profile
    end

    def initialize(params={})
      @printer_options = {}
      @default_ink_limit = 1.0
      @ink_limits = {}
      @ink_partitions = {}
      @gray_highlight = 0.06
      @gray_shadow = 0.06
      @gray_overlap = 0.10
      @gray_gamma = 1.0
      params.each { |key, value| send("#{key}=", value) }
    end

    def setup_defaults
      @printer_options = @printer.default_options
      @ink_limits = Hash[
        @printer.inks.map { |ink| [ink, @default_ink_limit] }
      ]
      default_partition = 1.0 / @printer.inks.length
      @ink_partitions = []
      @printer.inks.each_with_index do |ink, i|
        value = 1 - (i * default_partition)
        @ink_partitions << HashStruct.new(ink: ink, value: value)
      end
    end

    def save
      qtr_profile_path.dirname.mkpath
      qtr_profile_path.open('w') do |io|
        io.puts "PRINTER=#{@printer.name}"
        io.puts "PRINTER_OPTIONS=#{@printer_options.map { |k, v| [k, v].join('=') }.join(',')}"
        io.puts "GRAPH_CURVE=NO"
        io.puts "N_OF_INKS=#{@printer.inks.length}"
        io.puts "DEFAULT_INK_LIMIT=#{@default_ink_limit * 100}"
        @ink_limits.each do |ink, limit|
          io.puts "LIMIT_#{ink}=#{limit * 100}"
        end
        io.puts "N_OF_GRAY_PARTS=#{@ink_partitions.length}"
        @ink_partitions.each_with_index do |partition, i|
          io.puts "GRAY_INK_#{i+1}=#{partition.ink}"
          io.puts "GRAY_VAL_#{i+1}=#{partition.value * 100}"
        end
        io.puts "GRAY_HIGHLIGHT=#{@gray_highlight * 100}"
        io.puts "GRAY_SHADOW=#{@gray_shadow * 100}"
        io.puts "GRAY_OVERLAP=#{@gray_overlap * 100}"
        io.puts "GRAY_GAMMA=#{@gray_gamma}"
        io.puts "LINEARIZE=\"#{@linearization.map { |v| v * 100 }.join(' ')}\"" if @linearization
      end
    end

    def printer=(printer)
      case printer
      when Printer, nil
        @printer = printer
      else
        @printer = Printer.new(printer)
      end
    end

    def dir_path
      ProfilesDir + @name
    end

    def qtr_profile_path
      dir_path + "#{ProfileName}.txt"
    end

    def quad_file_path
      Pathname.new('/Library/Printers/QTR/quadtone') + @printer.name + "#{@name}.quad"
    end

    def install
      # filename needs to match name of profile for quadprofile to install it properly,
      # so temporarily make a symlink
      tmp_file = Pathname.new('/tmp') + "#{@name}.txt"
      qtr_profile_path.symlink(tmp_file)
      system('/Library/Printers/QTR/bin/quadprofile', tmp_file)
      tmp_file.unlink
    end

    def print_file(input_path, options={})
      options = HashStruct.new(options)
      printer_options = @printer_options.dup
      printer_options.merge!(options.printer_options) if options.printer_options
      if options.calibrate
        printer_options['ColorModel'] = 'QTCAL'
      else
        printer_options['ColorModel'] = 'QTRIP16'
        printer_options['ripCurve1'] = @name
      end
      renderer = Renderer.new(grayscale: !options.calibrate, page_size: @printer.page_size(printer_options['PageSize']))
      output_path = renderer.render(input_path)
      @printer.print_file(output_path, printer_options)
      output_path.unlink unless options.save_rendered
    end

    def show
      puts "Profile: #{@name}"
      puts "Printer: #{@printer.name}"
      puts "Printer options:"
      @printer_options.each do |key, value|
        puts "\t" + "#{key}: #{value}"
      end
      puts "Inks: #{@printer.inks.join(', ')}"
      puts "Default ink limit: #{@default_ink_limit}"
      puts "Gray settings:"
      puts "\t" + "Highlight: #{@gray_highlight}"
      puts "\t" + "Shadow: #{@gray_shadow}"
      puts "\t" + "Overlap: #{@gray_overlap}"
      puts "Gray gamma: #{@gray_gamma}"
      puts "Ink limits:"
      @ink_limits.each do |ink, limit|
        puts "\t" + "#{ink}: #{limit}"
      end
      puts "Ink partitions:"
      @ink_partitions.each do |ink, partition|
        puts "\t" + "#{ink}: #{partition.ink}: #{partition.value}"
      end
      puts "Linearization: #{@linearization ? @linearization.join(' ') : '(none)'}"
    end

  end

end