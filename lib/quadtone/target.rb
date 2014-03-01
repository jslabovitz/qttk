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
  
    Magick::RVG.dpi = 72    # also adds #pt, #in, etc., methods to Numeric
    
    LabelFontSize     = 10.pt
    ColumnLabelWidth  = 20.pt
    RowLabelHeight    = 20.pt
    PatchSize         = 32.pt
    GapSize           = 4.pt     # must be even
    MaxColumns        = 21
    MinWidth          = ColumnLabelWidth + (PatchSize + MaxColumns)
    MinHeight         = RowLabelHeight + PatchSize
    RowLabels         = (1 .. MaxColumns).to_a
    ColumnLabels      = ('A' .. 'Z').to_a
    
    attr_accessor :color_class
    attr_accessor :foreground_color
    attr_accessor :background_color
    attr_accessor :image_width
    attr_accessor :image_height
    
    def initialize(color_class, image_width, image_height)
      @color_class = color_class
      raise "Page width must be at least #{MinWidth}" if image_width < MinWidth
      raise "Page height must be at least #{MinHeight}" if image_height < MinHeight
      @image_width, @image_height = image_width, image_height
      if @color_class == Color::QTR
        @foreground_color = Color::QTR.new(:K, 0.5).to_pixel   # 50% black, to avoid reaching ink limit
        @background_color = Color::QTR.new(:K, 0).to_pixel     # 'white'
      else
        @foreground_color = Color::Gray.new(1).to_pixel
        @background_color = Color::Gray.new(0).to_pixel
      end
      @patches = Array.new([])
    end
    
    def read_ti1_file!(ti1_file)
      cgats = CGATS.new_from_file(ti1_file)
      section = cgats.sections.first
      raise "Expecting CGATS section with SINGLE_DIM_STEPS" unless section.header['SINGLE_DIM_STEPS']
      section.data.each_with_index do |set, i|
        
        raise "Can't add more patches" if num_patches == max_patches

        row = i / max_columns
        column = i % max_columns

        patch = HashStruct.new(
          :sample_id => set['SAMPLE_ID'],
          :row => row,
          :column => column,
          :input => @color_class.from_cgats(set),
          :output => Color::XYZ.from_cgats(set),
        )

        @patches[row] ||= []
        @patches[row][column] = patch
        
      end
    end
    
    def max_columns
      MaxColumns
    end
    
    def max_rows
      ((@image_height - RowLabelHeight) / PatchSize).floor
    end
    
    def num_rows
      @patches.length
    end
  
    def num_columns
      @patches.map(&:length).max
    end
    
    def max_patches
      max_columns * max_rows
    end
    
    def patches
      @patches.flatten.compact
    end
    
    def num_patches
      patches.length
    end
    
    def label_for_row_column(row, column)
      "#{ColumnLabels[column]}#{row + 1}"
    end
    
    def write_ti2_file(ti2_file)
      cgats_path = Pathname.new(ti2_file)
      cgats = CGATS.new
      
      first_patch = patches.first
      input_color_class = first_patch.input.class
      input_color_class = Color::RGB if input_color_class == Color::QTR
      output_color_class = first_patch.output.class
      
      # section 1: SINGLE_DIM_STEPS
      section = CGATS::Section.new
      section.header = {
        'CTI2' => nil,
        'DESCRIPTOR' => 'Argyll Calibration Target chart information 2',
        'ORIGINATOR' => 'qttk',
        'CREATED' => DateTime.now.to_s,
        'TARGET_INSTRUMENT' => 'GretagMacbeth i1 Pro',
        # 'APPROX_WHITE_POINT' => "95.106486 100.000000 108.844025",
        'COLOR_REP' => 'iRGB',
        # 'COLOR_REP' => color_rep,
        # 'WHITE_COLOR_PATCHES' => white_color_patches,
        # 'SINGLE_DIM_STEPS' => num_steps,
        'STEPS_IN_PASS' => num_columns,
        'PASSES_IN_STRIPS2' => num_rows,
      }
      section.data_fields = %w{SAMPLE_ID SAMPLE_LOC} + input_color_class.cgats_fields + output_color_class.cgats_fields
      patches.sort_by { |p| p.sample_id }.each do |patch|
        set = {
          'SAMPLE_ID' => patch.sample_id,
          'SAMPLE_LOC' => label_for_row_column(patch.row, patch.column),
        }
        set.update((input_color_class == Color::RGB ? patch.input.to_rgb : patch.input).to_cgats)
        set.update(patch.output.to_cgats)
        section << set
      end
      cgats.sections << section
      cgats_path.open('w') { |io| cgats.write(io) }
    end
    
    def write_image_file(image_file)
      draw_image.write(image_file) do
        self.depth = 8
        self.compression = Magick::ZipCompression
      end
    end
    
    def draw_image
      raise "No patches defined" unless @patches.flatten.length > 0
      rvg = Magick::RVG.new(@image_height, @image_width) do |canvas|
        canvas.background_fill = @background_color
        # canvas.translate(0, RowLabelHeight) do |g|
        #   draw_row_labels(g)
        # end
        # canvas.translate(ColumnLabelWidth, 0) do |g| 
        #   draw_column_labels(g)
        # end
        canvas.g.translate(ColumnLabelWidth, RowLabelHeight) do |g|
          draw_patches(g)
          draw_gaps(g)
        end
      end
      rvg.draw
    end
    
    private
    
    def draw_row_labels(g)
      num_rows.times do |row|
        label = RowLabels[row]
        y = row * PatchSize
        g.text(0, y + (PatchSize / 2), label).styles(:font_size => LabelFontSize, :fill => @foreground_color.to_color)
        y += PatchSize
        g.line(0, y, ColumnLabelWidth + ((MaxColumns + 2) * PatchSize), y).styles(:stroke => @foreground_color.to_color)
      end
    end

    def draw_column_labels(g)
      num_columns.times do |column|
        label = ColumnLabels[column]
        x, y = ((column + 1) * PatchSize) + (PatchSize / 2), RowLabelHeight - LabelFontSize
        g.text(x, y, label).styles(:text_anchor => 'middle', :font_size => LabelFontSize, :fill => @foreground_color.to_color)
      end
    end
    
    def draw_patches(g, component_index=nil)
      @patches.each_with_index do |columns, row|
        columns.each_with_index do |patch, column|
          w, h = PatchSize - GapSize, PatchSize - 1
          x, y = ((column + 1) * PatchSize) + GapSize, row * PatchSize
          g.rect(w, h, x, y).styles(:fill => patch.input.to_pixel.to_color)
  	    end
      end
    end
    
    def draw_gaps(g)
      
      @patches.each_with_index do |columns, row|
        columns.each_with_index do |patch, column|

          value = patch ? patch.input.value : 0
          
          prev_patch = column > 0 ? columns[column - 1] : nil
          prev_patch_value = (prev_patch ? prev_patch.input.value : 0)
          
          next_patch = columns[column + 1]
          next_patch_value = (next_patch ? next_patch.input.value : 0)
          
          x, y = ((column + 1) * PatchSize) + 1, row * PatchSize
          w, h = GapSize - 2, PatchSize - 1
          
          color = (prev_patch_value < 0.5 && value < 0.5) ? @foreground_color : @background_color
          g.rect(w, h, x, y).styles(:fill => color.to_color)
          
          color = (next_patch_value < 0.5 && value < 0.5) ? @foreground_color : @background_color
          g.rect(w, h, x + PatchSize, y).styles(:fill => color.to_color)          
          
        end
      end

    end
    
  end
  
end