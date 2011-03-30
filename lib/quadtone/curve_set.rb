module Quadtone
  
  class CurveSet
  
    attr_accessor :channels
    attr_accessor :curves
    attr_accessor :paper_sample
  
    def self.from_samples(samples)
      curve_set = new
      curve_set.read_samples!(samples)
      curve_set
    end
  
    def initialize(channels=nil)
      @channels = channels || self.class.all_channels
      @curves = []
      @paper_sample = nil
    end
  
    def generate
      @curves = []
      @channels.each do |channel|
        samples = [
          Sample.new(self.class.target_background_color, nil), 
          Sample.new(self.class.color_for_channel_value(channel, 0), nil)
        ]
        @curves << Curve.new(channel, samples)
      end
    end
  
    def read_samples!(samples)
      values = {}
      samples.each do |sample|
        input, output = sample.input, sample.output
        raise "Sample is missing output data: #{sample.inspect}" if output.nil?
        case input
        when Color::QTR
          curve_key = input.channel_key
          input = input.to_grayscale
        when Color::GrayScale
          curve_key = :G
        else
          raise "Unknown input type: #{input.inspect}"
        end
        curve_key = :P if input.density == 0
        output = output.to_grayscale
        # output.g = 1 if output.g > 1
        # output.g = 0 if output.g < 0
        values[curve_key] ||= {}
        values[curve_key][input] ||= []
        values[curve_key][input] << output
      end
      # average multiple readings and make samples
      values.each do |curve_key, inputs|
        values[curve_key] = inputs.map { |input, outputs| Sample.new(input, Color::GrayScale.from_density(outputs.map { |o| o.density }.average)) }
      end
      # find paper value
      paper_values = values.delete(:P) or raise "No paper sample found!"
      @paper_sample = paper_values.first
      # create actual curves
      @curves = values.map do |curve_key, samples|
        Curve.new(curve_key, [@paper_sample] + samples)
      end
      @channels = curves_by_channel.map { |c| c.key }
      ;;warn "read #{samples.length} samples covering channels: #{@channels.join(' ')}"
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

          # draw individual samples
          curve.samples.each do |sample|
            xml.circle(:cx => size * sample.input.density, :cy => size * (1 - sample.output.density), :r => 2, :fill => 'red', :stroke => 'none')
          end

          # # draw interpolated curve
          # points = (0..curve.max_input_density).step(1.0 / size).map do |input_density|
          #   output_density = curve.output_for_input(input_density)
          #   [size * input_density, size * (1 - output_density)]
          # end
          # xml.polyline(
          #   :fill => 'none', 
          #   :stroke => 'black', 
          #   :'stroke-width' => 1,
          #   :points => points.map { |pt| pt.join(',') }.join(' '))

          # draw interpolated curve based on fewer points
          smoothed_curve = curve.resample(21)
          points = (0..smoothed_curve.max_input_density).step(1.0 / size).map do |input_density|
            output_density = smoothed_curve.output_for_input(input_density)
            [size * input_density, size * (1 - output_density)]
          end
          xml.g(:fill => 'none', :stroke => 'green', :'stroke-width' => 1) do
            xml.polyline(:points => points.map { |pt| pt.join(',') }.join(' '))
          end
            
          # draw marker for dMax
          limit = curve.ink_limit
          point = [size * limit.input.density, size * (1 - limit.output.density)]
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
    
      def self.target_background_color
        Color::GrayScale.new(100)
      end
    
      def self.target_foreground_color
        Color::GrayScale.new(0)
      end
    
    end
  
  end
  
end