module Quadtone

  class QuadFile

    attr_accessor :curve_set

    ChannelAliases = {
      'C' => 'c',
      'M' => 'm',
      'Y' => 'y',
      'K' => 'k',
      'c' => 'lc',
      'm' => 'lm',
      'k' => 'lk',
    }

    def initialize(profile)
      @profile = profile
      @curve_set = CurveSet.new(channels: [], profile: @profile, type: :separation)
      load(@profile.quad_file_path)
    end

    # Read QTR quad (curve) file

    def load(quad_file)
      ;;warn "reading #{quad_file}"
      lines = Path.new(quad_file).open.readlines.map { |line| line.chomp.force_encoding('ISO-8859-1') }
      # process header
      channels = parse_channel_list(lines.shift)
      channels.each do |channel|
        samples = (0..255).to_a.map do |input|
          lines.shift while lines.first =~ /^#/
          line = lines.shift
          line =~ /^(\d+)$/ or raise "Unexpected value: #{line.inspect}"
          output = $1.to_i
          Sample.new(input: Color::Gray.new(k: 100 * (input / 255.0)), output: Color::Gray.new(k: 100 * (output / 65535.0)))
        end
        if @profile.inks.include?(channel)
          @curve_set.curves << Curve.new(channel: channel, samples: samples)
        end
      end
    end

    def parse_channel_list(line)
      # "## QuadToneRIP K,C,M,Y,LC,LM"
      # "## QuadToneRIP KCMY"
      line =~ /^##\s+QuadToneRIP\s+(.*)$/ or raise "Unexpected header line: #{line.inspect}"
      channel_list = $1
      case channel_list
      when /,/
        channel_list.split(',')
      else
        channel_list.chars.map { |c| ChannelAliases[c] }
      end.map { |c| c.downcase.to_sym }
    end

  end

end