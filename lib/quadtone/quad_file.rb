module Quadtone

  class QuadFile

    attr_accessor :curve_set

    ChannelAliases = {
      'C' => :c,
      'M' => :m,
      'Y' => :y,
      'K' => :k,
      'c' => :lc,
      'm' => :lm,
      'k' => :lk,
    }

    def initialize
      @curve_set = CurveSet.new(channels: Color::CMYK.component_names)
    end

    # Read QTR quad (curve) file

    def load(quad_file)
      lines = Pathname.new(quad_file).open.readlines.map { |line| line.chomp.force_encoding('ISO-8859-1') }

      # process header
      line = lines.shift
      line =~ /^##\s+QuadToneRIP\s+(.*)$/ or raise "Unexpected header value: #{line.inspect}"
      # "## QuadToneRIP K,C,M,Y,LC,LM"
      # "## QuadToneRIP KCMY"
      channel_list = $1
      channels = parse_channel_list($1)
      channels.each do |channel|
        samples = (0..255).to_a.map do |input|
          lines.shift while lines.first =~ /^#/
          line = lines.shift
          line =~ /^(\d+)$/ or raise "Unexpected value: #{line.inspect}"
          output = $1.to_i
          Sample.new(input: input / 255.0, output: output / 65535.0)
        end
        # curve = nil if curve.empty? || curve.uniq == [0]
        @curve_set << Curve.new(channel: channel, samples: samples)
      end
    end

    def parse_channel_list(str)
      if str =~ /,/
        str.split(',').map(&:downcase).map(&:to_sym)
      else
        str.chars.map { |c| ChannelNames[c] }
      end
    end

  end

end