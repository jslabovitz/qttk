module Quadtone
  
  class QuadCurves
  
    attr_accessor :channels
  
    def self.from_file(quad_file)
      quad = new
      quad.read_file!(quad_file)
      quad
    end
  
    def initialize
  		@curves = {}
  		@channels = []
    end

    ChannelAliases = {
      :c => :LC,
      :m => :LM,
      :k => :LK,
    }
  
    # Read QTR quad (curve) file
  
    def read_file!(quad_file)
  		lines = Pathname.new(quad_file).open.readlines.map { |line| line.chomp.force_encoding('ISO-8859-1') }

  	  # process header
  	  line = lines.shift
      line =~ /^##\s+QuadToneRIP\s+(.*)$/ or raise "Unexpected header value: #{line.inspect}"
  		# "## QuadToneRIP K,C,M,Y,LC,LM"
  		# "## QuadToneRIP KCMY"
      channel_list = $1
      @channels = (channel_list.split(channel_list =~ /,/ ? ',' : //)).map do |channel| 
        sym = channel.to_sym
        ChannelAliases[sym] || sym
      end
    
      # process channels in turn
      @channels.each do |channel|
        curve = []
        while lines.first =~ /^#/
          lines.shift
        end
        while lines.first =~ /^(\d+)$/
          num = $1.to_i
  		    curve << num / 65535.0
  		    lines.shift
  			end
  			curve = nil if curve.empty? || curve.uniq == [0]
  		  @curves[channel] = curve
  		end
    end
  
    def [](channel)
      @curves[channel]
    end
  
  end
  
end