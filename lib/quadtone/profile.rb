module Quadtone
  
  class Profile
    
    attr_accessor :base_dir
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :inks
    attr_accessor :characterization_curveset
    attr_accessor :linearization_curveset
    attr_accessor :default_ink_limit
    attr_accessor :gray_highlight
    attr_accessor :gray_shadow
    attr_accessor :gray_overlap
    attr_accessor :gray_gamma
    
    ProfileName = 'profile'
    CharacterizationName = 'characterization'
    LinearizationName = 'linearization'
    
    def self.from_dir(base_dir=Pathname.new('.'))
      profile = YAML::load((base_dir + "#{ProfileName}.yaml").open.read)
      profile.read_curvesets!
      profile
    end
    
    def initialize(params={})
      @base_dir = Pathname.new('.')
      @default_ink_limit = 1
      @gray_highlight = 6
      @gray_shadow = 6
      @gray_overlap = 10
      @gray_gamma = 1
      params.each { |key, value| method("#{key}=").call(value) }
    end
    
    def to_yaml_properties
      super - [:@characterization_curveset, :@linearization_curveset]
    end
    
    def read_curvesets!
      read_characterization_curveset!
      read_linearization_curveset!
    end
    
    def read_characterization_curveset!
      if characterization_measured_path.exist?
          if profile_path.exist? && characterization_measured_path.mtime > profile_path.mtime
          @characterization_curveset = CurveSet::QTR.from_samples(Target.from_cgats_file(characterization_measured_path).samples)
        else
          warn "Ignoring characterization file #{characterization_measured_path} that is not newer than profile."
        end
      end
    end
    
    def read_linearization_curveset!
      if linearization_measured_path.exist?
        if characterization_measured_path.exist? && linearization_measured_path.mtime > characterization_measured_path.mtime
          @linearization_curveset = CurveSet::Grayscale.from_samples(Target.from_cgats_file(linearization_measured_path).samples)
        else
          warn "Ignoring linearization file #{linearization_measured_path} that is not newer than characterization file #{characterization_measured_path}."
        end
      end
    end
    
    def characterization_curveset
      read_characterization_curveset! unless @characterization_curveset
      @characterization_curveset
    end
    
    def linearization_curveset
      read_linearization_curveset! unless @linearization_curveset
      @linearization_curveset
    end
        
    def save!
      profile_path.open('w') { |fh| YAML::dump(self, fh) }
    end
    
    def profile_path
      base_dir + "#{ProfileName}.yaml"
    end
    
    def characterization_reference_path
      @base_dir + "#{CharacterizationName}.reference.txt"
    end
    
    def characterization_measured_path
      @base_dir + "#{CharacterizationName}.measured.txt"
    end
    
    def linearization_reference_path
      @base_dir + "#{LinearizationName}.reference.txt"
    end
    
    def linearization_measured_path
      @base_dir + "#{LinearizationName}.measured.txt"
    end
    
    def qtr_profile_path
      @base_dir + (@name + '.txt')
    end
    
    def build_targets
      build_characterization_target
      build_linearization_target
    end
    
    def build_characterization_target
      curveset = CurveSet::QTR.new(@inks)
      curveset.generate_scale
      target = Target.new
      curveset.fill_target(target, :steps => 29, :oversample => 4)
      target.write_image_file(characterization_reference_path.with_extname('.tif'))
      target.write_cgats_file(characterization_reference_path)
    end
    
    def build_linearization_target
      curveset = CurveSet::Grayscale.new
      curveset.generate_scale
      target = Target.new
      curveset.fill_target(target, :steps => 51, :oversample => 4)
      target.write_image_file(linearization_reference_path.with_extname('.tif'))
      target.write_cgats_file(linearization_reference_path)
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
        scale = curve.input_scale(21)
        io.puts "LINEARIZE=\"#{scale.map { |point| 100 - (point.output.value * 100) }.join(' ')}\""
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
      printer = CupsPrinter.new(@printer)
      if options['ColorModel'] != 'QTCAL'
        options['ripCurve1'] = @name
      end
      printer.print_file(image_path, options)
    end
    
    def dump_printer_options
      ppd = CupsPPD.new(@printer)
      default_page_size = ppd.attribute('DefaultPageSize').first[:value]
      puts "Page size (#{default_page_size}): #{ppd.page_size(default_page_size).inspect}"
      # puts "Attributes:"
      # ppd.attributes.sort_by { |a| a[:name] }.each do |attribute|
      #   puts "\t" + "%s%s: %s" % [
      #     attribute[:name],
      #     attribute[:spec].empty? ? '' : " (#{attribute[:spec]})",
      #     attribute[:value]
      #   ]
      # end
      puts "Options:"
      ppd.options.sort_by { |o| o[:keyword] }.each do |option|
        puts "\t" + "%s: %s [%s]" % [
          option[:keyword],
          option[:default_choice],
          (option[:choices].map { |o| o[:choice] } - [option[:default_choice]]).join(' ')
        ]
      end
    end
  
  end
  
end