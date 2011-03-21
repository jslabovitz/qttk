module Quadtone
  
  class CGATS
  
    ColumnLabels = ('A' .. 'ZZ').to_a
  
    attr_accessor :header
    attr_accessor :data
    attr_accessor :data_fields
  
    def self.new_from_file(file)
      cgats = new
      state = :main
      Pathname.new(file).readlines.each do |line|
        line.chomp!
        line.sub!(/#.*/, '')
        line.strip!
        case state
        when :main
          case line
          when 'BEGIN_DATA_FORMAT'
            state = :data_format
          when 'BEGIN_DATA'
            state = :data
          else
            key, value = line.split(/\s+/, 2)
            if cgats.header[key]
              if !cgats.header[key].kind_of?(Array)
                cgats.header[key] = [cgats.header[key]]
              end
              cgats.header[key] << value
            else
              cgats.header[key] = value
            end
          end
        when :data_format
          case line
          when 'END_DATA_FORMAT'
            state = :main
          else
            line.split(/\s+/).each { |f| cgats.data_fields << f }
          end
        when :data
          case line
          when 'END_DATA'
            state = :main
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
              set[cgats.data_fields[i]] = value
            end
            cgats.data << set
          end
        end
      end
      cgats
    end
  
    def self.label_for_row_column(row, column)
      "#{ColumnLabels[column]}#{row + 1}"
    end
  
    def self.row_column_for_label(label)
      label =~ /^([A-Z]+)(\d+)$/ or raise "Can't parse label: #{label.inspect}"
      [$2.to_i - 1, ColumnLabels.index($1)]
    end
  
    def initialize
      @header = {}
      @data = []
      @data_fields = []
    end
  
    def write(io)
      # header
      @header.each { |k, v| io.puts "#{k}\t#{v}" }
      # data format
      io.puts "NUMBER_OF_FIELDS #{@data_fields.length}"
      io.puts 'BEGIN_DATA_FORMAT'
      io.puts @data_fields.join(' ')
      io.puts 'END_DATA_FORMAT'
      # data
      io.puts "NUMBER_OF_SETS #{@data.length}"
      io.puts 'BEGIN_DATA'
      @data.each { |set| io.puts(set.join("\t")) }
      io.puts 'END_DATA'
      nil
    end
  
    def <<(set)
      @data << set
    end
    
  end
  
end