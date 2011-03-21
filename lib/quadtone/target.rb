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
      Color::QTR        => %w{RGB_R RGB_G RGB_B},
      Color::GrayScale  => %w{GRAY},
      Color::Lab        => %w{LAB_L LAB_A LAB_B}
    }

    attr_accessor :patch_size
    attr_accessor :gap_size         # must be even
    attr_accessor :background_color
    attr_accessor :foreground_color
    attr_accessor :max_columns
    attr_accessor :max_rows
  
    def self.from_cgats_file(cgats_file)
      target = new
      target.read_cgats_file!(cgats_file)
      target
    end
  
    def initialize(height_inches=8)
      @patch_size = 28
      @gap_size = 4
      @background_color = Color::GrayScale.new(100)
      @foreground_color = Color::GrayScale.new(0)
      @max_columns = 21
      @max_rows = ((height_inches * 72) / @patch_size).round - 1
      @table = [[]]
    end
  
    def max_samples
      @max_columns * @max_rows
    end
  
    def <<(samples)
      [samples].flatten.each do |sample|
        raise "Too many samples (would exceed #{max_samples})" if samples.length + 1 == max_samples
        sample = Sample.new(sample, nil) unless sample.kind_of?(Sample)
        cur_row = @table[-1]
        if cur_row.length == @max_columns
          @table << (cur_row = [])
        end
        cur_row << sample
      end
    end
    
    def num_rows
      @table.length
    end
  
    def num_columns
      @table.map { |col| col.length }.max
    end
  
    def samples
      @table.flatten.compact
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
      label_size = 6
      label_font_size = 10
      image = Magick::Image.new(
        label_size + ((num_columns + 1) * (@gap_size + @patch_size)) + @gap_size, num_rows * @patch_size, 
        # work around inability to specify background color within Image.new's init block
        Magick::HatchFill.new(@background_color.html, @background_color.html)
      ) do
        self.depth = 8
        self.compression = Magick::ZipCompression
        # self.background_color = @background_color.html
      end
      # draw patches
      @table.each_with_index do |row, row_index|
        # draw row label
        text = Magick::Draw.new
        text.fill(@foreground_color.html)
        text.text_antialias(false)
        text.font_size(label_font_size)
        text.text(0, ((row_index + 1) * @patch_size) - label_font_size, (row_index + 1).to_s)
        text.draw(image)
        # draw columns
        row.each_with_index do |sample, column_index|
          x, y = label_size + (column_index + 1) * (@gap_size + @patch_size), row_index * @patch_size
          patch = Magick::Draw.new
          patch.fill(sample.input.html)
          patch.stroke_antialias(false)
          patch.rectangle(x + @gap_size, y, x + @gap_size + @patch_size - 0.5, y + @patch_size)
          patch.draw(image)
  	    end
      end
      # draw "black" gaps
      (num_columns + 1).times do |i|
        x = label_size + ((i + 1) * (@gap_size + @patch_size))
        black_gap = Magick::Draw.new
        black_gap.fill(@foreground_color.html)
        black_gap.stroke_antialias(false)
        black_gap.rectangle(x + (@gap_size / 2), 0, x + @gap_size - 0.5, num_rows * @patch_size)
        black_gap.draw(image)
      end
      image.write(image_file)
    end
    
  end
  
end