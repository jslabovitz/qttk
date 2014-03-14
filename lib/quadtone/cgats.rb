module Quadtone

  class CGATS

    attr_accessor :sections

    def self.new_from_file(file)
      cgats = new
      section_index = 0
      state = :header
      Pathname.new(file).readlines.each do |line|
        line.chomp!
        line.sub!(/#.*/, '')
        line.strip!
        next if line.empty?
        section = cgats.sections[section_index] || cgats.add_section
        case state
        when :header
          case line
          when 'BEGIN_DATA_FORMAT'
            state = :data_format
          when 'BEGIN_DATA'
            state = :data
          else
            key, value = line.split(/\s+/, 2)
            if section.header[key]
              if !section.header[key].kind_of?(Array)
                section.header[key] = [section.header[key]]
              end
              section.header[key] << value
            else
              section.header[key] = value
            end
          end
        when :data_format
          case line
          when 'END_DATA_FORMAT'
            state = :header
          else
            line.split(/\s+/).each { |f| section.data_fields << f }
          end
        when :data
          case line
          when 'END_DATA'
            # Emission data (BEGIN_DATA_EMISSION) may come after here, but we don't handle it.
            section_index += 1
            state = :header
          else
            values = line.split(/\s+/).map do |v|
              case v
              when /^-?\d+$/
                v.to_i
              when /^-?\d+\.\d+$/
                v.to_f
              else
                v.to_s
              end
            end
            set = {}
            values.each_with_index do |value, i|
              set[section.data_fields[i]] = value
            end
            section.data << set
          end
        end
      end
      cgats
    end

    def initialize
      @sections = []
    end

    def add_section
      @sections << Section.new
      @sections[-1]
    end

    def write(io)
      @sections.each do |section|
        section.write(io)
        io.puts
      end
      nil
    end

    class Section

      attr_accessor :header
      attr_accessor :data
      attr_accessor :data_fields

      def initialize
        @header = {}
        @data = []
        @data_fields = []
      end

      def <<(set)
        @data << set
      end

      def write(io)
        # header
        @header.each { |k, v| io.puts k.to_s + (v ? " \"#{v}\"" : '') }
        # data format
        io.puts
        io.puts "NUMBER_OF_FIELDS #{@data_fields.length}"
        io.puts 'BEGIN_DATA_FORMAT'
        io.puts @data_fields.join(' ')
        io.puts 'END_DATA_FORMAT'
        # data
        io.puts
        io.puts "NUMBER_OF_SETS #{@data.length}"
        io.puts 'BEGIN_DATA'
        @data.each do |set|
          fields = @data_fields.map do |f|
            case (d = set[f])
            when Float
              '%.05f' % d
            when String
              '"' + d + '"'
            else
              d
            end
          end
          io.puts fields.join(' ')
        end
        io.puts 'END_DATA'
        nil
      end

    end

  end

end