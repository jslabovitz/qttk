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
        path = Pathname.new("#{CharacterizationName}-#{ink}.ti3")
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
        @characterization_curveset.print_statistics
      end
    end
    
    def read_linearization_curveset!
      if linearization_measured_path.exist?
        # if characterization_measured_path.exist? && linearization_measured_path.mtime > characterization_measured_path.mtime && linearization_measured_path.mtime > @mtime
          @linearization_curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(linearization_measured_path).samples)
          @linearization_curveset.print_statistics
        # else
          # warn "Ignoring out of date linearization file: #{linearization_measured_path}"
        # end
      end
    end
            
    def save!
      profile_path.open('w') { |fh| YAML::dump(self, fh) }
    end
    
    def profile_path
      Pathname.new("#{ProfileName}.yaml")
    end
    
    def characterization_reference_path
      Pathname.new("#{CharacterizationName}.reference.txt")
    end
    
    def characterization_measured_path
      Pathname.new("#{CharacterizationName}.measured.txt")
    end
    
    def linearization_reference_path
      Pathname.new("#{LinearizationName}.reference.txt")
    end
    
    def linearization_measured_path
      Pathname.new("#{CharacterizationName}-G.ti3")
    end
    
    def qtr_profile_path
      Pathname.new(@name + '.txt')
    end
    
    def quad_file_path
      Pathname.new('/Library/Printers/QTR/quadtone') + @printer + "#{@name}.quad"
    end
    
    def build_targets(options={})
      build_characterization_target(options)
      build_linearization_target(options)
    end
    
    def build_characterization_target(options={})
      Target.build(@name, Color::QTR)
    end
    
    def build_linearization_target(options={})
      Target.build(@name, Color::Gray)
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
  
  end
  
end