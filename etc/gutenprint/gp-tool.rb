require 'quadtone'
include Quadtone

module Quadtone
  
  class GPTool < Tool
    
    attr_accessor :printer
    
    def parse_option(option, args)
      case option
      when '--printer', '-p'
        @printer = args.shift
      end
    end
  
    def run(image_file)
      image_file = Pathname.new(image_file)
      
      raise "Must specify printer with --printer" unless @printer

      gp = Gutenprint.new(@printer)
      
      gp_channels = gp.channels

      geometry = gp.geometry
      width = geometry[:width]
      height = geometry[:height]

      ;;warn "[reading #{image_file}]"      
      image_list = Magick::ImageList.new(image_file)
      # ;;warn "[rotating]"
      # ;;image_list.rotate!(90)
      # ;;warn "[scaling]"
      # scale = geometry[:x_resolution] / 72.0
      # image_list.sample!(scale)

      ;;warn "[writing output ESCP/2]"
      gp.print(
        :num_channels => gp_channels.length,
        :rows => image_list.rows,
        :columns => image_list.columns,
        :output_file => image_file.with_extname('.escp2'),
      ) do |io|

        image_list.rows.times do |row|
          row_str = image_list.columns.times.map do |col|
            image_list.to_a.map { |img| 65535 - img.pixel_color(col, row).intensity }.pack('S*')
          end.join
          io.print row_str
        end
      end
    end
  
  end
end