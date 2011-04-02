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
    
    PROFILE_FILENAME = 'profile.yaml'
    
    def self.from_dir(base_dir=Pathname.new('.'))
      YAML::load((base_dir + PROFILE_FILENAME).open.read)
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
    
    def save!
      (@base_dir + PROFILE_FILENAME).open('w') { |fh| YAML::dump(self, fh) }
    end
    
    def build_characterization_target
      reference_path = @base_dir + 'characterization.reference.txt'
      reference_curveset = CurveSet::QTR.new(@inks)
      reference_curveset.generate
      target = Target.new(17 - 1)   # tabloid size (11x17), for 17" roll paper, less margins
      # target = Target.new
      oversample = 4
      steps = target.max_samples / (reference_curveset.num_channels * oversample)
      reference_curveset.fill_target(target, :steps => steps, :oversample => oversample)
      target.write_image_file(reference_path.with_extname('.tif'))
      target.write_cgats_file(reference_path)
    end
    
    def build_linearization_target
      reference_path = @base_dir + 'linearization.reference.txt'
      reference_curveset = CurveSet::Grayscale.new
      reference_curveset.generate
      target = Target.new
      reference_curveset.fill_target(target, :steps => 51, :oversample => 4)
      target.write_image_file(reference_path.with_extname('.tif'))
      target.write_cgats_file(reference_path)
    end
    
    def qtr_profile(io)
      io.puts "PRINTER=#{@printer}"
      io.puts "GRAPH_CURVE=NO"
      io.puts
      
      io.puts "N_OF_INKS=#{@characterization_curveset.num_channels}"
      io.puts
      
      io.puts "DEFAULT_INK_LIMIT=#{@default_ink_limit * 100}"
      @characterization_curveset.curves_by_max_output_density.each do |curve|
        io.puts "LIMIT_#{curve.key}=#{curve.max_input_density * 100}"
      end
      io.puts
      
      io.puts "N_OF_GRAY_PARTS=#{@characterization_curveset.num_channels}"
      io.puts
      
      @characterization_curveset.separations.each_with_index do |separation, i|
        channel_key, density = *separation
        io.puts "GRAY_INK_#{i+1}=#{channel_key}"
        io.puts "GRAY_VAL_#{i+1}=#{density * 100}"
        io.puts
      end
      
      io.puts "GRAY_HIGHLIGHT=#{@gray_highlight}"
      io.puts "GRAY_SHADOW=#{@gray_shadow}"
      io.puts "GRAY_OVERLAP=#{@gray_overlap}"
      io.puts "GRAY_GAMMA=#{@gray_gamma}"
      io.puts
      
      if @linearization_curveset
        points = @linearization_curveset.curves.first.resample(21).points
        io.puts
        io.puts "LINEARIZE=\"#{points.map { |p| (1 - p.output) * 100 }.join(' ')}\""
      end
    end
  
    def install
      output_file = @base_dir + (@name + '.txt')
      ;;warn "writing QTR profile to #{output_file}"
      output_file.open('w') { |fh| qtr_profile(fh) }
      system('/Library/Printers/QTR/bin/quadprofile', output_file)
    end
  
  end
  
end