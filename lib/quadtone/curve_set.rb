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
        points = [
          Curve::Point.new(Color::Gray.new(0), Color::Gray.new(0)), 
          Curve::Point.new(Color::Gray.new(1), Color::Gray.new(1))
        ]
        Curve.new(channel, points)
      end
    end

    def read_samples!(samples)
      values = {}
      samples.each do |sample|
        raise "Sample is missing output data: #{sample.inspect}" if sample.output.nil?
        if sample.input.kind_of?(Color::QTR)
          channel = sample.input.channel
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
          point = Curve::Point.new(input, *outputs.first.class.average(outputs))
          ;;warn "#{input.inspect}: point error out of range: #{point.error}" if point.error >= 1
          point
        end
      end
      # find paper value
      paper_shades = values.delete(:P) or raise "No paper sample found!"
      @paper = paper_shades.first
      # create actual curves
      @curves = values.map do |channel, points|
        curve = Curve.new(channel, [@paper] + points)
        curve.find_ink_limits!
        curve
      end
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
        points = (0..255).to_a.map do |input|
          lines.shift while lines.first =~ /^#/
          line = lines.shift
          line =~ /^(\d+)$/ or raise "Unexpected value: #{line.inspect}"
          output = $1.to_i
  		    Curve::Point.new(input / 255.0, output / 65535.0)
  			end
        # curve = nil if curve.empty? || curve.uniq == [0]
  		  Curve.new(channel, points)
  		end
    end
    
    def num_channels
      @curves.length
    end
  
    def separations
      curves = @curves.sort_by { |c| c.ink_limit.output }.reverse
      darkest_curve = curves.shift
      separations = { darkest_curve.key => darkest_curve.points.last.input }
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

          # draw individual points
          curve.points.each do |point|
            xml.circle(:cx => size * point.input.value, :cy => size * (1 - point.output.value), :r => 2, :stroke => 'none', :fill => "rgb(#{point.output.to_rgb.join(',')})")
            #FIXME: If Lab color, somehow draw a/b values
            #FIXME: Parameterize error threshold
            if point.error > 0.05
              xml.circle(:cx => size * point.input.value, :cy => size * (1 - point.output.value), :r => 2 + (point.error * 10), :stroke => 'red', :fill => 'none')
            end
          end
          
          # draw interpolated curve
          points = curve.input_scale(size).map do |point|
            [size * point.input.value, size * (1 - point.output.value)]
          end
          xml.g(:fill => 'none', :stroke => 'green', :'stroke-width' => 1) do
            xml.polyline(:points => points.map { |pt| pt.join(',') }.join(' '))
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
  
    def fill_target(target, options={})
      steps = options[:steps] || 21
      oversample = options[:oversample] || 4
      target.background_color = self.class.target_background_color
      target.foreground_color = self.class.target_foreground_color
      samples = []
      @curves.each do |curve|
        # create scale for this channel
        scale_samples = curve.input_scale(steps).map do |point|
          Sample.new(self.class.color_for_channel_value(curve.key, point.input.value), nil)
        end
        # add multiple instances of each sample for each channel
        samples.concat(scale_samples * oversample)
      end
      # fill remaining slots with background color
      remaining = target.max_columns - (samples.length % target.max_columns)
      samples.concat([Sample.new(self.class.target_background_color, nil)] * remaining)
      ;;warn "generated #{samples.length} samples covering channels: #{@channels.join(' ')} using #{steps} steps @ #{oversample}x oversampling (plus #{remaining} paper samples)"
      # add samples randomly, starting with known seed so we get equivalent randomization
      target << samples.randomize(1)
      target
    end
  
    def dump
      @curves.each do |curve|
        curve.dump
      end
    end
  
    class QTR < CurveSet
    
      def self.all_channels
        Color::QTR::Channels
      end
    
      def self.color_for_channel_value(channel, value)
        Color::QTR.new(channel, value)
      end
    
      def self.target_background_color
        Color::QTR.new(:K, 0)
      end
    
      def self.target_foreground_color
        Color::QTR.new(:K, 1)
      end
    
    end
  
    class Grayscale < CurveSet
    
      def self.all_channels
        [:G]
      end
    
      def self.color_for_channel_value(channel, value)
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