# system
require 'pp'
require 'yaml'

# gems
require 'pathname3'
require 'rvg/rvg'   # includes 'rmagick'
require 'builder'   # for SVG generation
require 'cupsffi'

# ours
require 'quadtone/cgats'
require 'quadtone/color'
require 'quadtone/color/device_n'
require 'quadtone/color/gray'
require 'quadtone/color/lab'
require 'quadtone/color/qtr'
require 'quadtone/curve'
require 'quadtone/curve_set'
require 'quadtone/extensions/array'
require 'quadtone/extensions/math'
require 'quadtone/extensions/pathname3'
require 'quadtone/profile'
require 'quadtone/run'
require 'quadtone/sample'
require 'quadtone/separator'
require 'quadtone/spline'
require 'quadtone/target'
require 'quadtone/tool'
require 'quadtone/tools/add_printer'
require 'quadtone/tools/chart'
require 'quadtone/tools/dump'
require 'quadtone/tools/init'
require 'quadtone/tools/print'
require 'quadtone/tools/printer_options'
require 'quadtone/tools/profile'
require 'quadtone/tools/render'
require 'quadtone/tools/separate'
require 'quadtone/tools/target'
require 'quadtone/tools/test'