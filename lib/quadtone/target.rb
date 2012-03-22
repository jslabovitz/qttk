module Quadtone
  
  class Target
      
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
    
    def initialize
      @table = [[]]
    end
    
    def num_columns
      @table.map(&:length).max
    end
  
    def <<(samples)
      [samples].flatten.each do |sample|
        cur_row = @table[-1]
        if cur_row.length == max_columns
          raise "Not enough rows to add more samples" if num_rows == max_rows
          @table << (cur_row = [])
        end
        cur_row << sample
      end
    end
    
    def samples
      @table.flatten.compact
    end
    
    def read_cgats_file!(cgats_file)
      cgats = CGATS.new_from_file(cgats_file)
      cgats.data.each do |set|
        sample = Sample.from_cgats_data(set)
        row, column = CGATS::row_column_for_label(set['SAMPLE_LOC'])
        @table[row] ||= []
        @table[row][column] = sample
      end
    end
    
  end
  
end