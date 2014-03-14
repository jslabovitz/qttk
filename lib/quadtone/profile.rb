module Quadtone

  class Profile

    attr_accessor :name
    attr_accessor :printer
    attr_accessor :printer_options
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

    ProfilesDir = BaseDir + 'profiles'
    CurrentProfilePath = ProfilesDir + 'current'
    ProfileName = 'profile'

    def self.has_current_profile?
      CurrentProfilePath.symlink?
    end

    def self.current_profile_name
      CurrentProfilePath.readlink.basename.to_s if has_current_profile?
    end

    def self.make_current_profile(name)
      profile_path = ProfilesDir + name
      raise "Profile #{name.inspect} does not exist" unless profile_path.exist?
      CurrentProfilePath.unlink if CurrentProfilePath.exist?
      profile_path.symlink(CurrentProfilePath)
    end

    def self.profile_names
      Pathname.glob(ProfilesDir + '*').select { |p| !p.symlink? && p.directory? && p[0] != '.' }.map(&:basename)
    end

    def self.load_current_profile
      load(current_profile_name)
    end

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
        when 'INKS'
          profile.inks = value.split(',').map(&:downcase).map(&:to_sym)
        when 'DEFAULT_INK_LIMIT'
          profile.default_ink_limit = value.to_f / 100
        when /^LIMIT_(.+)$/
          profile.ink_limits[$1.downcase.to_sym] = value.to_f / 100
        when 'N_OF_GRAY_PARTS'
          # ignore
        when /^GRAY_INK_(\d+)$/
          i = $1.to_i - 1
          inks_by_num[i] = value.downcase.to_sym
        when /^GRAY_VAL_(\d+)$/
          i = $1.to_i - 1
          ink = inks_by_num[i]
          profile.ink_partitions[ink] = value.to_f / 100
        when 'GRAY_HIGHLIGHT'
          profile.gray_highlight = value.to_f / 100
        when 'GRAY_SHADOW'
          profile.gray_shadow = value.to_f / 100
        when 'GRAY_OVERLAP'
          profile.gray_overlap = value.to_f / 100
        when 'GRAY_GAMMA'
          profile.gray_gamma = value.to_f
        when 'LINEARIZE'
          profile.linearization = value.gsub('"', '').split(/\s+/).map { |v| Color::Lab.new([v.to_f]) }
        else
          warn "Unknown key in QTR profile: #{key.inspect}"
        end
      end
      profile.inks ||= profile.printer.inks
      profile.characterization_curveset = CurveSet.new(channels: profile.inks, profile: profile, type: :characterization)
      profile.linearization_curveset = CurveSet.new(channels: [:k], profile: profile, type: :linearization)
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

    def current_profile?
      self.class.has_current_profile? && @name == self.class.current_profile_name
    end

    def make_current_profile
      self.class.make_current_profile(@name)
    end

    def save
      qtr_profile_path.dirname.mkpath
      qtr_profile_path.open('w') do |io|
        io.puts "PRINTER=#{@printer.name}"
        io.puts "PRINTER_OPTIONS=#{@printer_options.map { |k, v| [k, v].join('=') }.join(',')}" if @printer_options
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

    def printer=(printer)
      case printer
      when Printer, nil
        @printer = printer
      else
        @printer = Printer.new(printer)
      end
      @printer_options ||= @printer.default_options
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

    def html_path
      dir_path + "#{ProfileName}.html"
    end

    def ink_limit(ink)
      @ink_limits[ink] || @default_ink_limit
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
      if options.printer_options
        options.printer_options.each do |key, value|
          printer_options[key.to_s] = value
        end
      end
      if options.calibrate
        printer_options['ColorModel'] = 'QTCAL'
      else
        printer_options['ripCurve1'] = @name
      end
      if options.render
        renderer = Renderer.new(grayscale: !options.calibrate, page_size: @printer.page_size(printer_options['PageSize']), rotate: options.rotate)
        output_path = renderer.render(input_path)
      else
        output_path = input_path
      end
      @printer.print_file(output_path, printer_options) if options.print
      if options.save_rendered
        output_path
      else
        output_path.unlink if options.render
        nil
      end
    end

    def show
      puts "Profile: #{@name}"
      puts "Printer: #{@printer.name}"
      puts "Printer options:"
      @printer_options.each do |key, value|
        puts "\t" + "#{key}: #{value}"
      end
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
          html.h1("Profile: #{@name}")
        end
      end
      html.target!
    end

    def check
      #FIXME: check values
    end

  end

end