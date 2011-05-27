require 'quadtone'
include Quadtone

module Quadtone
  
  class PrinterOptionsTool < Tool
    
    def run(*image_files)
      profile = Profile.from_dir(@profile_dir)
      # profile.print_printer_attributes
      profile.print_printer_options
    end
    
  end
  
end