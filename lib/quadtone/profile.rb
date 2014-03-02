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

    def setup_default_inks
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

    def setup
      raise "No printer specified" unless @printer
      ImportantPrinterOptions.each do |option_name|
        option = @printer.options.find { |o| o[:keyword] == option_name }
        if option
          @printer_options[option[:keyword]] ||= option[:default_choice]
        else
          warn "Printer does not support option: #{option_name.inspect}"
        end
      end
    end

    def install
      # filename needs to match name of profile for quadprofile to install it properly,
      # so temporarily make a symlink
      tmp_file = Pathname.new('/tmp') + "#{@name}.txt"
      qtr_profile_path.symlink(tmp_file)
      system('/Library/Printers/QTR/bin/quadprofile', tmp_file)
      tmp_file.unlink
    end

    def print_image(image_path, options={})
      if options['ColorModel'] != 'QTCAL'
        options = options.merge('ripCurve1' => @name)
      end
      @printer.print_file(image_path, @printer_options.merge(options))
    end

    def show
      puts "Profile: #{@name}"
      puts "Printer: #{@printer.name}"
      puts "Printer options:"
      @printer_options.each do |key, value|
        puts "\t" + "#{key}: #{value}"
      end
      puts "Inks: #{@printer.inks.join(', ')}"
      puts "Last modification time: #{@qtr_profile_path.mtime}"
    end

  end

end