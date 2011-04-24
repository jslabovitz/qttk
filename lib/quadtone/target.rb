=begin

  Target specs:
  
    width of page               11"
    width of strip              <= 9.5" (24.13cm)
    patch size (scan direction) >= 10mm (28pt)
    patch size (perpendicular)  8mm (23pt)
    gap size in scan direction  0.5mm - 1.0mm (2pt)
    optimum patches per strip   21
    
=end

module Quadtone
  
  class Target
  
    Fields = {
      Color::QTR  => %w{RGB_R RGB_G RGB_B},
      Color::Gray => %w{GRAY},
      Color::Lab  => %w{LAB_L LAB_A LAB_B}
    }
    
    LabelFontSize     = 10
    ColumnLabelWidth  = 20
    RowLabelHeight    = 20
    PatchSize         = 32
    GapSize           = 4     # must be even
    MaxColumns        = 21
    
    attr_accessor :background_color
    attr_accessor :foreground_color
    attr_accessor :max_rows
  
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
  
    def initialize(height_inches=8)
      @background_color = Color::Gray.new(0)
      @foreground_color = Color::Gray.new(1)
      @max_rows = ((height_inches * 72) / PatchSize).round - 1
      @table = [[]]
    end
    
    def max_columns
      MaxColumns
    end
    
    def max_samples
      MaxColumns * @max_rows
    end
  
    def <<(samples)
      [samples].flatten.each do |sample|
        raise "Too many samples (would exceed #{max_samples})" if samples.length + 1 == max_samples
        cur_row = @table[-1]
        if cur_row.length == MaxColumns
          @table << (cur_row = [])
        end
        cur_row << sample
      end
    end
    
    def num_rows
      @table.length
    end
  
    def num_columns
      @table.map(&:length).max
    end
  
    def samples
      @table.flatten.compact
    end
    
    def color_mode
      samples.first.input.class
    end
  
    def read_cgats_file!(cgats_file)
      cgats = CGATS.new_from_file(cgats_file)
      cgats.data.each do |set|
        sample = Sample.from_cgats_data(set)
        row, column = CGATS::row_column_for_label(set['SAMPLE_NAME'])
        @table[row] ||= []
        @table[row][column] = sample
      end
    end
  
    def write_cgats_file(cgats_file)
      cgats_file = Pathname.new(cgats_file)
      cgats = CGATS.new
      cgats.header['LGOROWLENGTH'] = num_rows
      cgats.data_fields = %w{SampleID SAMPLE_NAME}
      samples = @table.flatten
      if (sample = samples.find { |s| s.input })
        cgats.data_fields += Fields[sample.input.class]
      end
      if (sample = samples.find { |s| s.output })
        cgats.data_fields += Fields[sample.output.class]
      end
      sample_id = 1
      # output by columns, not rows!
      num_columns.times do |column_index|
        @table.each_with_index do |row, row_index|
          sample = @table[row_index][column_index] or next
          cgats << [
            sample_id,
            CGATS::label_for_row_column(row_index, column_index),
            *sample.to_cgats_data]
          sample_id += 1
        end
      end
      cgats_file.open('w') { |fh| cgats.write(fh) }
    end
    
    def write_image_file(image_file)
      image.write(image_file) do
        self.depth = 8
        self.compression = Magick::ZipCompression
      end
    end
    
    def image(size={:width=>(11*72)-(9*2),:height=>(8.5*72)-(9*2)})
      Magick::RVG.dpi = 72
      rvg = Magick::RVG.new(size[:width], size[:height]) do |canvas|
        canvas.background_fill = @background_color.html
        canvas.g.translate(ColumnLabelWidth, RowLabelHeight) do |patches|
          draw_patches(patches)
          draw_gaps(patches)
        end
        canvas.g.translate(0, RowLabelHeight) { |g| draw_row_labels(g) }
        canvas.g.translate(ColumnLabelWidth, 0) { |g| draw_column_labels(g) }
      end
      rvg.draw
    end
    
    private
    
    def draw_row_labels(g)
      num_rows.times do |row|
        label = (row + 1).to_s
        x, y = 0, (row * PatchSize) + (PatchSize / 2)
        g.text(x, y, label).styles(:font_size => LabelFontSize, :fill => @foreground_color.html)
      end
    end

    def draw_column_labels(g)
      num_columns.times do |col|
        label = CGATS::ColumnLabels[col]
        x, y = ((col + 1) * PatchSize) + (PatchSize / 2), RowLabelHeight - LabelFontSize
        g.text(x, y, label).styles(:text_anchor => 'middle', :font_size => LabelFontSize, :fill => @foreground_color.html)
      end
    end
    
    def draw_patches(g)
      @table.each_with_index do |columns, row|
        columns.each_with_index do |sample, col|
          w, h = PatchSize, PatchSize
          x, y = (col + 1) * PatchSize, row * PatchSize
          g.rect(w, h, x, y).styles(:fill => sample.input.html)
  	    end
      end
    end
    
    def draw_gaps(g)
      (num_columns + 1).times do |col|
        w, h = (GapSize / 2) - 1, (num_rows * PatchSize)
        x, y = (col + 1) * PatchSize, 0
        g.rect(w, h, x, y).styles(:fill => @background_color.html)
        g.rect(w, h, x + (GapSize / 2), y).styles(:fill => @foreground_color.html)
      end
    end
    
  end
  
end