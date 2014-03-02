require 'quadtone'
include Quadtone

module Quadtone

  class AddPrinterTool < Tool

    def run(printer)

      #FIXME: move this into Printer class

      unless %x{lpstat -v #{printer} 2>/dev/null}.empty?
        raise ToolUsageError, "Printer #{printer.inspect} already exists"
      end

      curves_dir          = Pathname.new('/Library/Printers/QTR/quadtone') + printer
      cups_data_dir       = Pathname.new(%x{cups-config --datadir}.chomp)
      cups_serverbin_dir  = Pathname.new(%x{cups-config --serverbin}.chomp)

      model = printer.split(/[-_=]/).first
      model_ppd = "C/#{model}.ppd.gz"
      ppd_file = cups_data_dir + 'model' + model_ppd

      raise "QuadToneRIP does not support printer model #{model.inspect}" unless ppd_file.exist?

      uri = loc = nil

      File.popen(cups_serverbin_dir + 'backend' + 'usb').readlines.each do |line|
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