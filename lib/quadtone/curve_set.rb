module Quadtone
  
  class CurveSet
  
    attr_accessor :channels
    attr_accessor :curves
    attr_accessor :paper
  
    def self.from_samples(samples)
      curve_set = new
      curve_set.read_samples!(samples)
      curve_set
    end
    
    def self.from_quad_file(quad_file)
      curve_set = new
      curve_set.read_quad_file!(quad_file)
      curve_set
    end
    
    def initialize(channels=nil)
      @channels = channels || self.class.all_channels
      @curves = []
      @paper = nil
    end
    
    def generate_scale
      @curves = @channels.map do |channel|
        samples = [
          Sample.new(Color::Gray.new(0), Color::Gray.new(0)), 
          Sample.new(Color::Gray.new(1), Color::Gray.new(1))
        ]
        Curve.new(channel, samples)
      end
    end

    def read_samples!(samples)
      values = {}
      samples.each do |sample|
        raise "Sample is missing output data: #{sample.inspect}" if sample.output.nil?
        case sample.input
        when Color::QTR
          channel = sample.input.channel_name
        else
          channel = :G
        end
        channel = :P if sample.input.value == 0
        values[channel] ||= {}
        values[channel][sample.input] ||= []
        values[channel][sample.input] << sample.output
      end
      # average multiple readings
      values.each do |channel, inputs|
        values[channel] = inputs.sort.map do |input, outputs|
          sample = Sample.new(input, *outputs.first.class.average(outputs))
          warn "sample error out of range: input=#{input.inspect}, error=#{sample.error}" if sample.error && sample.error >= 1
          sample
        end
      end
      # find paper value
      paper_shades = values.delete(:P) or raise "No paper sample found!"
      @paper = paper_shades.first
      # create actual curves
      @curves = values.map do |channel, samples|
        curve = Curve.new(channel, [@paper] + samples)
        curve.find_ink_limits!
        if curve.ink_limit.input.value == 0
          ;;warn "Ignoring ink #{channel} because ink limit is zero"
          nil
        else
          curve
        end
      end.compact
      @curves.sort_by! { |c| @channels.index(c.key) }
      ;;warn "read #{samples.length} samples covering channels: #{@curves.map { |c| c.key }.join(' ')}"
    end
    
    ChannelAliases = {
      'c' => :LC,
      'm' => :LM,
      'k' => :LK,
    }
    
    # Read QTR quad (curve) file
  
    def read_quad_file!(quad_file)
  		lines = Pathname.new(quad_file).open.readlines.map { |line| line.chomp.force_encoding('ISO-8859-1') }
      
  	  # process header
  	  line = lines.shift
      line =~ /^##\s+QuadToneRIP\s+(.*)$/ or raise "Unexpected header value: #{line.inspect}"
  		# "## QuadToneRIP K,C,M,Y,LC,LM"
  		# "## QuadToneRIP KCMY"
      channel_list = $1
      @curves = ($1.split(channel_list =~ /,/ ? ',' : //)).map { |c| ChannelAliases[c] || c.to_sym }.map do |channel|
        samples = (0..255).to_a.map do |input|
          lines.shift while lines.first =~ /^#/
          line = lines.shift
          line =~ /^(\d+)$/ or raise "Unexpected value: #{line.inspect}"
          output = $1.to_i
          Sample.new(Color::Gray.new(input / 255.0), Color::Gray.new(output / 65535.0))
  			end
        # curve = nil if curve.empty? || curve.uniq == [0]
  		  Curve.new(channel, samples)
  		end
    end
    
    def num_channels
      @curves.length
    end
  
    def separations
      curves = @curves.sort_by { |c| c.ink_limit.output }.reverse
      darkest_curve = curves.shift
      separations = { darkest_curve.key => darkest_curve.samples.last.input }
      curves.each do |curve|
        separations[curve.key] = darkest_curve.find_relative_value(curve.ink_limit.output) \
          or raise "Can't find relative density for #{curve.ink_limit.output.density} in curve #{darkest_curve.key.inspect}"
      end
      separations
    end
  
    def to_svg(options={})
      size = options[:size] || 500
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.g(:width => size, :height => size) do
        xml.g(:stroke => 'blue') do
          xml.rect(:x => 0, :y => 0, :width => size, :height => size, :fill => 'none', :'stroke-width' => 1)
          xml.line(:x1 => 0, :y1 => size, :x2 => size, :y2 => 0, :'stroke-width' => 0.5)
        end
        @curves.each do |curve|

          # draw individual samples
          curve.samples.each do |sample|
            xml.circle(:cx => size * sample.input.value, :cy => size * (1 - sample.output.value), :r => 2, :stroke => 'none', :fill => "rgb(#{sample.output.to_rgb.join(',')})")
            if sample.error && sample.error > 0.05
              xml.circle(:cx => size * sample.input.value, :cy => size * (1 - sample.output.value), :r => 2 + (sample.error * 10), :stroke => 'red', :fill => 'none')
            end
          end
          
          # draw interpolated curve
          samples = curve.interpolated_samples(size).map do |sample|
            [size * sample.input.value, size * (1 - sample.output.value)]
          end
          xml.g(:fill => 'none', :stroke => 'green', :'stroke-width' => 1) do
            xml.polyline(:points => samples.map { |pt| pt.join(',') }.join(' '))
          end
          
          # draw marker for ink limit (chroma)
          if (limit = curve.chroma_limit)
            x, y = size * limit.input.value, size * (1 - limit.output.value)
            xml.g(:stroke => 'magenta', :'stroke-width' => 2) do
              xml.line(:x1 => x, :y1 => y + 8, :x2 => x, :y2 => y - 8)
            end
          end
          
          # draw marker for ink limit (density)
          if (limit = curve.density_limit)
            x, y = size * limit.input.value, size * (1 - limit.output.value)
            xml.g(:stroke => 'black', :'stroke-width' => 2) do
              xml.line(:x1 => x, :y1 => y + 8, :x2 => x, :y2 => y - 8)
            end
          end
          
          # draw marker for ink limit (delta E)
          if (limit = curve.delta_e_limit)
            x, y = size * limit.input.value, size * (1 - limit.output.value)
            xml.g(:stroke => 'cyan', :'stroke-width' => 2) do
              xml.line(:x1 => x, :y1 => y + 8, :x2 => x, :y2 => y - 8)
            end
          end
        end
      end
      xml.target!
    end
  
    def write_svg_file(file, options={})
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.declare!(:DOCTYPE, :svg, :PUBLIC, "-//W3C//DTD SVG 1.1//EN", "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd")
      xml.svg(:version => '1.1', :xmlns => 'http://www.w3.org/2000/svg') do
        xml << to_svg(options)
      end
      Pathname.new(file).open('w').write(xml.target!)
    end
  
    def print_statistics
      puts "Curve set:"
      @curves.each do |curve|
        dmin, dmax = curve.dynamic_range
        puts "\t" + "%3s: ink limits: chroma = %3s%%, density = %3s%%, deltaE = %3s%%; density: min = %3d%% (%3.2f D), max = %3d%% (%.2f D), range = %.2f D" % [
          curve.key,
          curve.chroma_limit ? ( curve.chroma_limit.input.value * 100).to_i : '---',
          curve.density_limit ? (curve.density_limit.input.value * 100).to_i : '---',
          curve.delta_e_limit ? (curve.delta_e_limit.input.value * 100).to_i : '---',
          (dmin.value * 100).to_i, Math::log10(100.0 / dmin.l),
          (dmax.value * 100).to_i, Math::log10(100.0 / dmax.l),
          Math::log10(dmin.l / dmax.l),
        ]
      end
    end
  
    def dump
      @curves.each do |curve|
        curve.dump
      end
    end
  
    class QTR < CurveSet
    
      def self.all_channels
        Color::QTR.component_names
      end
    
      def self.color_for_channel_value(channel, value)
        raise "Channel #{channel.inspect} must be one of: #{Color::QTR.component_names}" unless Color::QTR.component_names.include?(channel)
        Color::QTR.new(channel, value)
      end
    
      def self.target_background_color
        Color::QTR.new(:K, 0)
      end
    
      def self.target_foreground_color
        Color::QTR.new(:K, 1)
      end
    
    end
  
    class DeviceN < CurveSet
    
      def self.all_channels
        Color::DeviceN.component_names
      end
    
      def self.color_for_channel_value(channel, value)
        raise "Channel #{channel.inspect} must be one of: #{Color::DeviceN.component_names}" unless Color::DeviceN.component_names.include?(channel)
        components = [0] * Color::DeviceN.num_components
        components[channel] = value
        Color::DeviceN.new(components)
      end
    
      def self.target_background_color
        Color::DeviceN.new([0])
      end
    
      def self.target_foreground_color
        Color::DeviceN.new([1])
      end
    
    end
  
    class Grayscale < CurveSet
    
      def self.all_channels
        Color::Gray.component_names
      end
    
      def self.color_for_channel_value(channel, value)
        raise "Channel #{channel.inspect} must be one of: #{Color::Gray.component_names}" unless Color::Gray.component_names.include?(channel)
        Color::Gray.new(value)
      end
          
      def self.target_background_color
        Color::Gray.new(0)
      end
    
      def self.target_foreground_color
        Color::Gray.new(1)
      end
    
    end

    class QuadFile < QTR
    
    end
  
  end
  
end