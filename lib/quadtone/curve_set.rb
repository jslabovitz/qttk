module Quadtone
  
  class CurveSet
  
    attr_accessor :channels
    attr_accessor :curves
    attr_accessor :paper_density
  
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
      @paper_density = nil
    end
  
    def generate
      @curves = []
      @channels.each do |channel|
        points = [
          Curve::Point.new(0, nil), 
          Curve::Point.new(1, nil)
        ]
        @curves << Curve.new(channel, points)
      end
    end
  
    def read_samples!(samples)
      points = {}
      samples.each do |sample|
        raise "Sample is missing output data: #{sample.inspect}" if sample.output.nil?
        channel, input = self.class.channel_density_for_color(sample.input)
        output = sample.output.density
        channel = :P if input == 0
        #FIXME: Do we want to clip?
        ;;output = 0 if output < 0
        warn "Sample has input out of range: #{sample.inspect}" unless (0..1).include?(input)
        warn "Sample has output out of range: #{sample.inspect}" unless (0..1).include?(output)
        warn "Sample doesn't have channel: #{sample.inspect}" unless channel
        points[channel] ||= {}
        points[channel][input] ||= []
        points[channel][input] << output
      end
      # average multiple readings
      points.each do |channel, inputs|
        points[channel] = inputs.map { |input, outputs| Curve::Point.new(input, outputs.average) }
      end
      # find paper value
      paper_shades = points.delete(:P) or raise "No paper sample found!"
      @paper_density = paper_shades.first
      # create actual curves
      @curves = points.map do |channel, points|
        Curve.new(channel, [@paper_density] + points)
      end
      @channels = curves_by_channel.map { |c| c.key }
      ;;warn "read #{samples.length} samples covering channels: #{@channels.join(' ')}"
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
      @channels = curves_by_channel.map { |c| c.key }
    end
    
    def curves_by_max_output_density
      @curves.sort_by { |c| c.max_output_density }.reverse
    end
  
    def curves_by_channel
      @curves.sort_by { |c| @channels.index(c.key) }
    end
  
    def trim_curves!
      @curves.each { |curve| curve.trim! }
    end
  
    def num_channels
      @curves.length
    end
  
    def limits
      Hash[
        curves_by_channel.map { |c| [c.key, c.max_input_density] }
      ]
    end
  
    def separations
      curves = curves_by_max_output_density
      darkest_curve = curves.shift
      separations = { darkest_curve.key => 1 }
      curves.each do |curve|
        separations[curve.key] = darkest_curve.find_relative_density(curve.max_output_density) \
          or raise "Can't find relative density for #{curve.max_output_density} in curve #{darkest_curve.key.inspect}"
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
        curves_by_channel.each do |curve|

          # draw individual points
          curve.points.each do |point|
            xml.circle(:cx => size * point.input, :cy => size * (1 - point.output), :r => 2, :fill => 'red', :stroke => 'none')
          end

          # # draw interpolated curve
          # points = (0..curve.max_input_density).step(1.0 / size).map do |input|
          #   output = curve.output_for_input(input)
          #   [size * input, size * (1 - output)]
          # end
          # xml.polyline(
          #   :fill => 'none', 
          #   :stroke => 'black', 
          #   :'stroke-width' => 1,
          #   :points => points.map { |pt| pt.join(',') }.join(' '))

          # draw interpolated curve based on fewer points
          smoothed_curve = curve.resample(21)
          points = (0..smoothed_curve.max_input_density).step(1.0 / size).map do |input|
            output = smoothed_curve.output_for_input(input)
            [size * input, size * (1 - output)]
          end
          xml.g(:fill => 'none', :stroke => 'green', :'stroke-width' => 1) do
            xml.polyline(:points => points.map { |pt| pt.join(',') }.join(' '))
          end
            
          # draw marker for dMax
          limit = curve.ink_limit
          point = [size * limit.input, size * (1 - limit.output)]
          xml.g(:stroke => 'green', :'stroke-width' => 2) do
            xml.line(:x1 => point[0], :y1 => point[1] + 8, :x2 => point[0], :y2 => point[1] - 8)
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
      limits = options[:limits] || {}
      target.background_color = self.class.target_background_color
      target.foreground_color = self.class.target_foreground_color
      scale = density_scale(steps)
      samples = []
      curves_by_channel.each do |curve|
        # create scale for this channel
        limit = limits[curve.key]
        ;;warn "limiting #{curve.key} to #{limit}" if limit
        scale_samples = scale.map { |d| self.class.color_for_channel_value(curve.key, 1 - (limit ? (d * limit) : d)) }
        # add multiple instances of each sample for each channel
        samples.concat(scale_samples * oversample)
      end
      # fill remaining slots with background color
      remaining = target.max_columns - (samples.length % target.max_columns)
      samples.concat([self.class.target_background_color] * remaining)
      ;;warn "generated #{samples.length} samples covering channels: #{@channels.join(' ')} using #{steps} steps @ #{oversample}x oversampling (plus #{remaining} paper samples)"
      # add samples randomly, starting with known seed so we get equivalent randomization
      target << samples.randomize(1)
      target
    end
  
    def density_scale(steps=21, range=0..1)
      range.step(1.0 / (steps - 1)).to_a
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
    
      def self.channel_density_for_color(color)
        [color.channel_key, color.density]
      end
    
      def self.target_background_color
        Color::QTR.new(:K, 1)
      end
    
      def self.target_foreground_color
        Color::QTR.new(:K, 0)
      end
    
    end
  
    class Grayscale < CurveSet
    
      def self.all_channels
        [:G]
      end
    
      def self.color_for_channel_value(channel, value)
        Color::GrayScale.from_fraction(value)
      end
      
      def self.channel_density_for_color(color)
        [:G, color.density]
      end
    
      def self.target_background_color
        Color::GrayScale.new(100)
      end
    
      def self.target_foreground_color
        Color::GrayScale.new(0)
      end
    
    end

    class QuadFile < QTR
    
    end
  
  end
  
end