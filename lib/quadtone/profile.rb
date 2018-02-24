module Quadtone

  class Profile

    attr_accessor :printer
    attr_accessor :printer_options
    attr_accessor :medium
    attr_accessor :inks
    attr_accessor :ink_partitions
    attr_accessor :ink_limits
    attr_accessor :linearization
    attr_accessor :default_ink_limit
    attr_accessor :gray_highlight
    attr_accessor :gray_shadow
    attr_accessor :gray_overlap
    attr_accessor :gray_gamma
    attr_accessor :characterization_curveset
    attr_accessor :linearization_curveset
    attr_accessor :test_curveset

    ProfilesDir = BaseDir / 'profiles'
    ProfileName = 'profile.txt'

    def self.profile_names
      ProfilesDir.children.select { |p| p.directory? && p.basename.to_s[0] != '.' }.map(&:basename).map(&:to_s)
    end

    def self.load(name)
      profile = Profile.new
      profile.load(name)
      profile
    end

    def initialize(params={})
      @printer_options = nil
      @default_ink_limit = 1.0
      @ink_limits = {}
      @ink_partitions = {}
      @gray_highlight = 0.06
      @gray_shadow = 0.06
      @gray_overlap = 0.10
      @gray_gamma = 1.0
      params.each { |key, value| send("#{key}=", value) }
    end

    def name
      [
        @printer.name.gsub(/[^-A-Z0-9]/i, ''),
        @medium.gsub(/[^-A-Z0-9]/i, ''),
      ].flatten.join('-')
    end

    def load(name)
      inks_by_num = []
      (ProfilesDir / name / ProfileName).readlines.each do |line|
        line.chomp!
        line.sub!(/#.*/, '')
        line.strip!
        next if line.empty?
        key, value = line.split('=', 2)
        case key
        when 'PRINTER'
          @printer = Printer.new(value)
        when 'PRINTER_OPTIONS'
          @printer_options = Hash[ value.split(',').map { |o| o.split('=') } ]
        when 'MEDIUM'
          @medium = value
        when 'GRAPH_CURVE'
          # ignore
        when 'N_OF_INKS'
          # ignore
        when 'INKS'
          @inks = value.split(',').map(&:downcase).map(&:to_sym)
        when 'DEFAULT_INK_LIMIT'
          @default_ink_limit = value.to_f / 100
        when /^LIMIT_(.+)$/
          @ink_limits[$1.downcase.to_sym] = value.to_f / 100
        when 'N_OF_GRAY_PARTS'
          # ignore
        when /^GRAY_INK_(\d+)$/
          i = $1.to_i - 1
          inks_by_num[i] = value.downcase.to_sym
        when /^GRAY_VAL_(\d+)$/
          i = $1.to_i - 1
          ink = inks_by_num[i]
          @ink_partitions[ink] = value.to_f / 100
        when 'GRAY_HIGHLIGHT'
          @gray_highlight = value.to_f / 100
        when 'GRAY_SHADOW'
          @gray_shadow = value.to_f / 100
        when 'GRAY_OVERLAP'
          @gray_overlap = value.to_f / 100
        when 'GRAY_GAMMA'
          @gray_gamma = value.to_f
        when 'LINEARIZE'
          @linearization = value.gsub('"', '').split(/\s+/).map { |v| Color::Lab.new([v.to_f]) }
        else
          warn "Unknown key in QTR profile: #{key.inspect}"
        end
      end
      @characterization_curveset = CurveSet.new(channels: @inks, profile: self, type: :characterization)
      @linearization_curveset = CurveSet.new(channels: [:k], profile: self, type: :linearization)
    end

    def save
      qtr_profile_path.dirname.mkpath
      qtr_profile_path.open('w') do |io|
        io.puts "PRINTER=#{@printer.name}"
        io.puts "PRINTER_OPTIONS=#{@printer_options.map { |k, v| [k, v].join('=') }.join(',')}" if @printer_options
        io.puts "MEDIUM=#{@medium}"
        io.puts "GRAPH_CURVE=YES"
        io.puts "INKS=#{@inks.join(',')}"
        io.puts "N_OF_INKS=#{@inks.length}"
        io.puts "DEFAULT_INK_LIMIT=#{@default_ink_limit * 100}"
        @ink_limits.each do |ink, limit|
          io.puts "LIMIT_#{ink.upcase}=#{limit * 100}"
        end
        io.puts "N_OF_GRAY_PARTS=#{@ink_partitions.length}"
        @ink_partitions.each_with_index do |partition, i|
          ink, value = *partition
          io.puts "GRAY_INK_#{i+1}=#{ink.upcase}"
          io.puts "GRAY_VAL_#{i+1}=#{value * 100}"
        end
        io.puts "GRAY_HIGHLIGHT=#{@gray_highlight * 100}"
        io.puts "GRAY_SHADOW=#{@gray_shadow * 100}"
        io.puts "GRAY_OVERLAP=#{@gray_overlap * 100}"
        io.puts "GRAY_GAMMA=#{@gray_gamma}"
        io.puts "LINEARIZE=\"#{@linearization.map(&:l).join(' ')}\"" if @linearization
      end
    end

    def dir_path
      ProfilesDir / name
    end

    def qtr_profile_path
      dir_path / ProfileName
    end

    def quad_file_path
      Path.new('/Library/Printers/QTR/quadtone') / @printer.name / "#{name}.quad"
    end

    def ink_limit(ink)
      @ink_limits[ink] || @default_ink_limit
    end

    def install
      # filename needs to match name of profile for quadprofile to install it properly,
      # so temporarily make a symlink
      tmp_file = Path.new('/tmp') / "#{name}.txt"
      qtr_profile_path.symlink(tmp_file.to_s)
      system('/Library/Printers/QTR/bin/quadprofile', tmp_file.to_s)
      tmp_file.unlink
    end

    def print_file(input_path, options={})
      options = HashStruct.new(options)
      printer_options = @printer_options.dup
      if options.printer_options
        options.printer_options.each do |key, value|
          printer_options[key.to_s] = value
        end
      end
      if options.calibrate
        printer_options['ColorModel'] = 'QTCAL'
      else
        printer_options['ripCurve1'] = name
      end
      @printer.print_file(input_path, printer_options)
    end

    def show
      puts "Profile: #{name}"
      puts "Printer: #{@printer.name}"
      puts "Printer options:"
      @printer_options.each do |key, value|
        puts "\t" + "#{key}: #{value}"
      end
      puts "Medium: #{@medium}"
      puts "Inks: #{@inks.join(', ')}"
      puts "Default ink limit: #{@default_ink_limit}"
      puts "Ink limits:"
      @ink_limits.each do |ink, limit|
        puts "\t" + "#{ink.upcase}: #{limit}"
      end
      puts "Gray settings:"
      puts "\t" + "Highlight: #{@gray_highlight}"
      puts "\t" + "Shadow: #{@gray_shadow}"
      puts "\t" + "Overlap: #{@gray_overlap}"
      puts "Gray gamma: #{@gray_gamma}"
      puts "Ink partitions:"
      @ink_partitions.each do |ink, value|
        puts "\t" + "#{ink.upcase}: #{value}"
      end
      puts "Linearization: #{@linearization.join(', ')}" if @linearization
    end

    def to_html
      html = Builder::XmlMarkup.new(indent: 2)
      html.html do
        html.head do
        end
        html.body do
          html.h1("Profile: #{name}")
        end
      end
      html.target!
    end

    def check
      #FIXME: check values
    end

  end

end