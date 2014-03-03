module Quadtone

  module Tools

    class Chart < Tool

      attr_accessor :open
      attr_accessor :quick_look

      def parse_option(option, args)
        case option
        when '--open'
          @open = true
        when '--quicklook'
          @quicklook = true
        end
      end

      def run
        html_path = @profile.html_path
        html_path.open('w') { |io| io.write(@profile.to_html) }
        ;;puts "Saved HTML to #{html_path}"
        system 'open', html_path if @open
        system 'qlmanage', '-p', html_path if @quick_look
      end

    end

  end

end