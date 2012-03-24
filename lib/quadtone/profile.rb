module Quadtone
  
  class Profile
    
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :printer_options
    attr_accessor :inks
    attr_accessor :characterization_curveset
    attr_accessor :linearization_curveset
    attr_accessor :default_ink_limit
    attr_accessor :gray_highlight
    attr_accessor :gray_shadow
    attr_accessor :gray_overlap
    attr_accessor :gray_gamma
    attr_accessor :mtime
    
    ProfileName = 'profile'
    CharacterizationName = 'characterization'
    LinearizationName = 'linearization'
    ImportantPrinterOptions = %w{MediaType Resolution ripSpeed stpDither}
    
    def self.from_dir(dir='.')
      file = Pathname.new(dir) + "#{ProfileName}.yaml"
      profile = YAML::load(file.open.read)
      profile.mtime = file.mtime
      profile.setup
      profile
    end
    
    def initialize(params={})
      @mtime = Time.now
      @printer_options = {}
      @default_ink_limit = 1
      @gray_highlight = 6
      @gray_shadow = 6
      @gray_overlap = 10
      @gray_gamma = 1
      params.each { |key, value| method("#{key}=").call(value) }
      setup
    end
    
    def setup
      raise "No printer specified" unless @printer
      @ppd = CupsPPD.new(@printer.dup)
      ppd_options = @ppd.options
      ImportantPrinterOptions.each do |option_name|
        option = ppd_options.find { |o| o[:keyword] == option_name }
        if option
          @printer_options[option[:keyword]] ||= option[:default_choice]
        else
          warn "Printer does not support option: #{option_name.inspect}"
        end
      end
      # FIXME: It would be nice to get this path programmatically.
      ppd_file = Pathname.new("/etc/cups/ppd/#{@printer}.ppd")
      ink_description = ppd_file.readlines.find { |l| l =~ /^\*%Inks\s*(.*?)\s*$/ } or raise "Can't find inks description for printer #{@printer.inspect}"
      @inks = ink_description.chomp.split(/\s+/, 2).last.split(/,/).map { |ink| ink.to_sym }
      read_curvesets!
    end
    
    def to_yaml_properties
      super - [:@characterization_curveset, :@linearization_curveset, :@ppd]
    end
    
    def read_curvesets!
      read_characterization_curveset!
      read_linearization_curveset!
    end
    
    def read_characterization_curveset!
      samples = []
      @inks.each do |ink|
        path = Pathname.new("#{@name}-#{ink}.ti3")
        if path.exist?
          if path.mtime > @mtime
            target = Target.from_cgats_file(path)
            new_samples = target.samples.each { |s| s.input = Color::QTR.new(ink, s.input.value) }
            warn "#{new_samples.length} measurements found for ink #{ink.inspect}"
            samples += new_samples
          else
            warn "Ignoring out of date characterization file: #{path.to_s.inspect}"
          end
        end
      end
      if samples.empty?
        warn "No samples found"
      else
        @characterization_curveset = CurveSet::QTR.from_samples(samples)
      end
    end
    
    def read_linearization_curveset!
      if linearization_measured_path.exist?
        # if characterization_measured_path.exist? && linearization_measured_path.mtime > characterization_measured_path.mtime && linearization_measured_path.mtime > @mtime
          @linearization_curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(linearization_measured_path).samples)
        # else
          # warn "Ignoring out of date linearization file: #{linearization_measured_path}"
        # end
      end
    end
    
    def measure(options={})
      spot = options[:spot] || false
      @inks.each_with_index do |ink, i|
        sub_name = Pathname.new("#{@name}-#{ink}")
        ti2_path = sub_name.with_extname('.ti2')
        ti3_path = sub_name.with_extname('.ti3')
        if !ti3_path.exist? || ti3_path.mtime < ti2_path.mtime
          puts; puts "Ready to read #{sub_name} in strip mode ('p' for patch, 'q' to skip): "
          case STDIN.gets.chomp
          when 'p'
            spot = true
          when 'q'
            next
          end
        	run('chartread',
        	  (i > 0) ? '-N' : nil,   # disable auto calibration unless first time through
        	  spot ? '-p' : nil,      # measure by spot if specified, otherwise by strip
        	  '-n',                   # don't save spectral info
        	  '-l',                   # save L*a*b rather than XYZ
        	  '-H',                   # use high resolution spectrum mode
        	  sub_name)
    	  end
      end
    end
    
    def save!
      profile_path.open('w') { |fh| YAML::dump(self, fh) }
    end
    
    def profile_path
      Pathname.new("#{ProfileName}.yaml")
    end
    
    def characterization_measured_path(ink)
      Pathname.new("#{@name}-#{ink}.measured.txt")
    end
    
    def linearization_measured_path
      Pathname.new("#{@name}-G.ti3")
    end
    
    def qtr_profile_path
      Pathname.new(@name + '.txt')
    end
    
    def quad_file_path
      Pathname.new('/Library/Printers/QTR/quadtone') + @printer + "#{@name}.quad"
    end
    
    def build_targets
      build_characterization_target
      build_linearization_target
    end
    
    def build_characterization_target
      Target.build(@name, @inks, Color::QTR)
    end
    
    def build_linearization_target
      Target.build(@name, [:G], Color::Gray)
    end
    
    def qtr_profile(io)
      
      raise "No characterization is set" unless @characterization_curveset
      
      io.puts "PRINTER=#{@printer}"
      io.puts "GRAPH_CURVE=NO"
      io.puts
      
      io.puts "N_OF_INKS=#{@characterization_curveset.num_channels}"
      io.puts
      
      io.puts "DEFAULT_INK_LIMIT=#{@default_ink_limit * 100}"
      @characterization_curveset.curves.each do |curve|
        io.puts "LIMIT_#{curve.key}=#{curve.ink_limit.input.value * 100}"
      end
      io.puts
      
      io.puts "N_OF_GRAY_PARTS=#{@characterization_curveset.num_channels}"
      io.puts
      
      @characterization_curveset.separations.each_with_index do |separation, i|
        channel, input = *separation
        io.puts "GRAY_INK_#{i+1}=#{channel}"
        io.puts "GRAY_VAL_#{i+1}=#{input.value * 100}"
        io.puts
      end
      
      io.puts "GRAY_HIGHLIGHT=#{@gray_highlight}"
      io.puts "GRAY_SHADOW=#{@gray_shadow}"
      io.puts "GRAY_OVERLAP=#{@gray_overlap}"
      io.puts "GRAY_GAMMA=#{@gray_gamma}"
      io.puts
      
      if @linearization_curveset
        curve = @linearization_curveset.curves.first
        samples = curve.interpolated_samples(21)
        io.puts "LINEARIZE=\"#{samples.map { |p| p.output.l }.join(' ')}\""
      end
    end
    
    def write_qtr_profile
      ;;warn "writing QTR profile to #{qtr_profile_path}"
      qtr_profile_path.open('w') { |io| qtr_profile(io) }
    end
  
    def install
      system('/Library/Printers/QTR/bin/quadprofile', qtr_profile_path)
    end
    
    def print_image(image_path, options={})
      printer = CupsPrinter.new(@printer.dup)
      options['ripCurve1'] = @name if options['ColorModel'] != 'QTCAL'
      options.merge!(@printer_options)
      warn "Printing:"
      warn "\t" + image_path
      warn "Options:"
      options.each do |key, value|
        warn "\t" + "%10s: %s" % [key, value.inspect]
      end
      printer.print_file(image_path, options)
    end
    
    def page_size(name=nil)
      name ||= @ppd.attribute('DefaultPageSize').first[:value]
      size = @ppd.page_size(name)
      size[:imageable_width] = (size[:margin][:right] - size[:margin][:left]).pt
      size[:imageable_height] = (size[:margin][:top] - size[:margin][:bottom]).pt
      size
    end
    
    def print_printer_attributes
      puts "Attributes:"
      @ppd.attributes.sort_by { |a| a[:name] }.each do |attribute|
        puts "\t" + "%25s: %s%s" % [
          attribute[:name],
          attribute[:value].inspect,
          attribute[:spec].empty? ? '' : " [#{attribute[:spec].inspect}]"
        ]
      end
    end

    def print_printer_options
      puts "Options:"
      @ppd.options.sort_by { |o| o[:keyword] }.each do |option|
        puts "\t" + "%25s: %s [%s]" % [
          option[:keyword],
          option[:default_choice].inspect,
          (option[:choices].map { |o| o[:choice] } - [option[:default_choice]]).map { |o| o.inspect }.join(', ')
        ]
      end
    end
    
    def to_html
      html = Builder::XmlMarkup.new(:indent => 2)
      html.declare!(:DOCTYPE, :html)
      html.html do
        html.head do
          html.title("Profile: #{@name}")
        end
        html.body do
          html.h1("Profile: #{@name}")
          html.ul do
            html.li("Printer: #{@printer}")
            html.li("Printer options:")
            html.ul do
              @printer_options.each do |key, value|
                html.li("#{key}: #{value}")
              end
            end
            html.li("Inks: #{@inks.join(', ')}")
            html.li("Last modification time: #{@mtime}")
          end
          html.div do
            html.h2("Characterization curves")
            if @characterization_curveset
              html << @characterization_curveset.to_html
            else
              html.text('(Not defined)')
            end
          end
          html.div do
            html.h2("Linearization curves")
            if @linearization_curveset
              html << @linearization_curveset.to_html
            else
              html.text('(Not defined)')
            end
          end
        end
      end
      html.target!
    end

  end
  
end