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
  
    Colors = [
      Color::QTR,
      Color::DeviceN,
      Color::Gray,
      Color::Lab
    ]
    
    Magick::RVG.dpi = 72    # also adds #pt, #in, etc., methods to Numeric
    
    LabelFontSize     = 10.pt
    ColumnLabelWidth  = 20.pt
    RowLabelHeight    = 20.pt
    PatchSize         = 32.pt
    GapSize           = 4.pt     # must be even
    MaxColumns        = 21
    
    attr_accessor :background_color
    attr_accessor :foreground_color
    attr_reader :image_width
    attr_reader :image_height
  
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
    
    def self.min_width
      ColumnLabelWidth + (PatchSize + MaxColumns)
    end
    
    def self.min_height
      RowLabelHeight + PatchSize
    end
    
    def initialize(image_width=nil, image_height=nil)
      if image_width && image_height
        raise "Page width must be at least #{self.class.min_width}" if image_width < self.class.min_width
        raise "Page height must be at least #{self.class.min_height}" if image_height < self.class.min_height
        @image_width, @image_height = image_width, image_height
      end
      @background_color = Color::Gray.new(0)
      @foreground_color = Color::Gray.new(1)
      @table = [[]]
    end
    
    def max_columns
      MaxColumns
    end
    
    def max_rows
      ((image_height - RowLabelHeight) / PatchSize).floor
    end
    
    def max_samples
      max_columns * max_rows      
    end
    
    def num_rows
      @table.length
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
        cgats.data_fields += sample.input.class.cgats_fields
      end
      if (sample = samples.find { |s| s.output })
        cgats.data_fields += sample.output.class.cgats_fields
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
      ;;warn "[generating target image]"
      img = image
      ;;warn "[writing target image]"
      img.write(image_file) do
        #FIXME: This should be 16 for non-QTR use, but how to set outside of this scope?
        self.depth = 8
        self.compression = Magick::ZipCompression
      end
      ;;warn "[done writing image]"
    end
    
    def image
      image_list = Magick::ImageList.new
      flatten = (color_mode != Color::DeviceN)
      color_mode.component_names.length.times do |component_index|
        first = (component_index == 0)
        rvg = Magick::RVG.new(@image_width, @image_height) do |canvas|
          canvas.background_fill = @background_color.html if first || !flatten
          canvas.g.translate(ColumnLabelWidth, RowLabelHeight) do |g|
            draw_patches(g, component_index)
            draw_gaps(g) if first
          end
          if first
            canvas.g.translate(0, RowLabelHeight) { |g| draw_row_labels(g) }
            canvas.g.translate(ColumnLabelWidth, 0) { |g| draw_column_labels(g) }
          end
        end
        image_list << rvg.draw
      end
      if flatten
        image_list.flatten_images
      else
        image_list
      end
    end
    
    private
    
    def draw_row_labels(g)
      num_rows.times do |row|
        label = (row + 1).to_s
        y = row * PatchSize
        g.text(0, y + (PatchSize / 2), label).styles(:font_size => LabelFontSize, :fill => @foreground_color.html)
        y += PatchSize
        g.line(0, y, ColumnLabelWidth + ((MaxColumns + 2) * PatchSize), y).styles(:stroke => @foreground_color.html)
      end
    end

    def draw_column_labels(g)
      num_columns.times do |col|
        label = CGATS::ColumnLabels[col]
        x, y = ((col + 1) * PatchSize) + (PatchSize / 2), RowLabelHeight - LabelFontSize
        g.text(x, y, label).styles(:text_anchor => 'middle', :font_size => LabelFontSize, :fill => @foreground_color.html)
      end
    end
    
    def draw_patches(g, component_index=nil)
      @table.each_with_index do |columns, row|
        columns.each_with_index do |sample, col|
          if component_index.nil? || sample.input.components[component_index] > 0
            w, h = PatchSize - GapSize, PatchSize - 1
            x, y = ((col + 1) * PatchSize) + GapSize, row * PatchSize
            g.rect(w, h, x, y).styles(:fill => sample.input.html)
          end
  	    end
      end
    end
    
    def draw_gaps(g)
      @table.each_with_index do |columns, row|
        0.upto(columns.length).each do |col|
          prev_sample = col > 0 ? columns[col - 1] : nil
          sample = columns[col]
          value = sample ? sample.input.value : 0
          prev_value = prev_sample ? prev_sample.input.value : 0
          x, y = ((col + 1) * PatchSize) + 1, row * PatchSize
          w, h = GapSize - 2, PatchSize - 1
          color = (prev_value < 0.5 && value < 0.5) ? @foreground_color : @background_color
          g.rect(w, h, x, y).styles(:fill => color.html) if color
        end
      end

    end
    
  end
  
end