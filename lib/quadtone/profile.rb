module Quadtone
  
  class Profile
  
    attr_accessor :name
    attr_accessor :printer
    attr_accessor :unlimited_qtr_curveset
    attr_accessor :limited_qtr_curveset
    attr_accessor :grayscale_curveset
  
    def initialize(name, printer)
      @name = name
      @printer = printer
    end
  
    def print(io)
    
      stanzas = []
    
      stanzas << [ "PRINTER=#{@printer}" ]
      stanzas << [ "GRAPH_CURVE=NO" ]
    
      stanzas << [ "N_OF_INKS=#{@limited_qtr_curveset.num_channels}" ]
    
      stanzas << (stanza = [])
      stanzas << [ "DEFAULT_INK_LIMIT=100" ]
      @unlimited_qtr_curveset.curves_by_max_output_density.each do |curve|
        stanza << "LIMIT_#{curve.key}=#{curve.max_input_density * 100}"
      end
    
      stanzas << [ "N_OF_GRAY_PARTS=#{@limited_qtr_curveset.num_channels}" ]
    
      @limited_qtr_curveset.separations.each_with_index do |separation, i|
        channel_key, density = *separation
        stanzas << (stanza = [])
        stanza << "GRAY_INK_#{i+1}=#{channel_key.to_s}"
        stanza << "GRAY_VAL_#{i+1}=#{density * 100}"
      end
    
      if true
        stanzas << (stanza = [])
        stanza << "GRAY_HIGHLIGHT=6"
        stanza << "GRAY_SHADOW=6"
        stanza << "GRAY_OVERLAP=10"
        stanza << "GRAY_GAMMA=1"
      end
    
      if @grayscale_curveset
        stanzas << (stanza = [])
        samples = @grayscale_curveset.curves.first.resample(21).samples
        stanza << "LINEARIZE=\"#{samples.map { |s| (1 - s.output.density) * 100 }.join(' ')}\""
      end

      stanzas.each do |stanza|
        stanza.each do |line|
          io.puts line
        end
        io.puts
      end
    end
  
    def install
      output_file = Pathname.new(@name + '.txt')
      ;;warn "writing QTR profile to #{output_file}"
      output_file.open('w') { |fh| print(fh) }
      system('/Library/Printers/QTR/bin/quadprofile', output_file)
    end
  
  end
  
end