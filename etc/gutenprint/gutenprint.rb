module Quadtone
  
  class Gutenprint
    
    attr_accessor :printer
    
    def initialize(printer)
      @printer = printer
    end
    
    def channels
      run_filter(%w{-s}).split(/\n/).map { |s| s.split(/:\s+/, 2) }
    end

    def geometry
      Hash[
        run_filter(%w{-g}).split(/\n/).map do |s| 
          key, value = s.split(/:\s+/, 2)
          value = case value
          when /^\d+$/
            value.to_i
          when /^\d+\.\d+$/
            value.to_f
          else
            value
          end
          [key.to_sym, value]
        end
      ]
    end

    def print(args, &block)
      run_filter(
        [
          '-c', args[:num_channels],
          '-h', args[:rows],
          '-w', args[:columns],
          '-o', args[:output_file],
          '-'
        ], 'w'
      ) do |io|
        yield(io)
      end
    end
    
    private
    
    def run_filter(args, mode='r', &block)
      cmd = [
        File.join(File.realpath(File.dirname($0)), 'gutenprint-filter'),
        '-d', @printer,
      ] + args
      cmd = cmd.map { |c| c.to_s }
      ;;warn cmd.join(' ')

      IO.popen(cmd, mode) do |io|
        if block_given?
          yield(io)
        else
          io.read
        end
      end
    end

    # currently unused
    class ChannelMap

      def initialize(gp_channels)
        @qtr_channels = {}
        gp_channels.each_with_index do |channel, i|
          short, long = *channel
          qtr_key = long.split(/\s+/).map { |s| (s == 'Black') ? 'K' : s[0] }.join.to_sym
          raise "Unknown channel: #{long}" unless Color::QTR::Channels.index(qtr_key)
          @qtr_channels[qtr_key] = i
        end
      end

      def qtr_to_raw_channel_index(qtr_color)
        @qtr_channels[qtr_color.channel]
      end

    end

  end
  
end