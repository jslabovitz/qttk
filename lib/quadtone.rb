# system
require 'pp'
require 'yaml'

# gems
require 'color'
require 'gsl'
require 'pathname3'
require 'rmagick'
require 'builder'   # for SVG generation

# ours
require 'quadtone/cgats'
require 'quadtone/curve'
require 'quadtone/curve_set'
require 'quadtone/extensions/array'
require 'quadtone/extensions/color/grayscale'
require 'quadtone/extensions/color/lab'
require 'quadtone/extensions/color/qtr'
require 'quadtone/extensions/pathname3'
require 'quadtone/profile'
require 'quadtone/sample'
require 'quadtone/separator'
require 'quadtone/target'
require 'quadtone/tool'
require 'quadtone/tools/add_printer'
require 'quadtone/tools/characterize'
require 'quadtone/tools/dump'
require 'quadtone/tools/init'
require 'quadtone/tools/linearize'
require 'quadtone/tools/separate'
require 'quadtone/tools/test'