module Quadtone

  module Tools

    class AddPrinter < Tool

      def load_profile
        false
      end

      def run(printer)

        #FIXME: move this into Printer class

        unless %x{lpstat -v #{printer} 2>/dev/null}.empty?
          raise ToolUsageError, "Printer #{printer.inspect} already exists"
        end

        curves_dir          = Path.new('/Library/Printers/QTR/quadtone') / printer
        ppds_dir            = Path.new('/Library/Printers/PPDs/Contents/Resources')
        cups_serverbin_dir  = Path.new(%x{cups-config --serverbin}.chomp)
        cups_backend_usb_tool = cups_serverbin_dir / 'backend' / 'usb'

        model = printer.split(/[-_=]/).first
        model_ppd = "#{model}.ppd.gz"
        ppd_file = ppds_dir / model_ppd

        raise "QuadToneRIP does not support printer model #{model.inspect}" unless ppd_file.exist?

        uri = loc = nil

        File.popen(cups_backend_usb_tool.to_s).readlines.each do |line|
          #FIXME: Too fragile -- use 'lpinfo' to find all printers
          if line =~ /(usb:.*EPSON.*#{Regexp.escape(model.sub(/^Quad/, ''))})/
            uri = $1
            loc = "USB Printer"
            break
          end
        end

        if uri.nil?
          loop do
            print "Enter IP address of IPP printer, or <return> to cancel: "
            ipp = STDIN.gets.chomp
            if ipp.empty?
              warn "Install cancelled."
              return
            end
            if ipp =~ /^\d+\.\d+\.\d+\.\d+$/
              uri = "lpd://#{ipp}"
              loc = "Network Printer IPP = #{ipp}"
              break
            end
            warn "Invalid IPP number: #{ipp.inspect}"
          end
        end

        warn "Creating printer #{printer.inspect}"
        system('lpadmin',
          '-p', printer,
          '-E',
          '-m', model_ppd,
          '-L', loc,
          '-v', uri)
        raise "Failed to create printer" unless $? == 0

        curves_dir.mkpath
      end

    end

  end

end