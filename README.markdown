# Quadtone Toolkit (QTTK)

QTTK provides a set of tools for printmakers who use the quadtone inkjet printing process.  It works in conjunction with the [QuadtoneRIP](http://www.quadtonerip.com) (QTR) grayscale printing system.

At the moment, the software consists largely of libraries of code (written in the [Ruby](http://ruby-lang.org) programming language) and a single command-line tool.  Hence, it is probably not interesting to most printmakers unless they are either programmers or people comfortable with the Unix command line.  Additionally, printmakers who are happy with Epson's 'automatic black and white' mode, the default QTR profiles, or the [Piezography](http://piezography.com) system can probably feel comfortable in staying with the process they currently use.

However, if you are interested in printing on obscure papers, hand-mixing your own inks, or otherwise want more control and knowledge over the printmaking process, these tools may help.  I originally wrote them because I was dissatisfied with the perception of the quadtone process being 'black magic,' inaccessible, or unscientific.  It is my hope that tools like QTTK will increase the understanding and acceptance of the quadtone inkjet process.

At some point, given sufficient interest and motivation, I may write a graphical interface (GUI) to the underlying code.  In the meantime, please enjoy the art and craft of the [Unix command line](http://en.wikipedia.org/wiki/Command-line_interface).


## Capabilities

QTTK enables you to:

  - Generate profiling targets to be printed and analyzed.  Many parameters can be set, including paper size, color mode (either QTR calibration or grayscale), ink channels, ink limits, and patch oversampling rates.  In addition to an image file (TIFF), a reference data file is also generated, which can be used by MeasureTool or other color profiling systems.
  
  - Analyze measurements of printed reference targets.  Individual ink channels are detected, as well as tonal response curves, maximum-density points, and other data.  Grayscale ink separations can be easily calculated, as well as linearization curves for grayscale targets.
  
  - Create visual charts and graphs of analyzed information, including response curves and density scales.
  
  - Build and install QTR profiles, based on measured data, avoiding complex and error-prone manual calculations.
  
  - Preview how images will print through particular QTR profiles, actually separating a grayscale image into the ink channels as represented in the the QTR curve files.

QTTK intentionally makes few assumptions about equipment and materials. This allows for flexibility, as well as dealing with 'worst case' scenarios. Say you've obtained an old printer with a broken magenta channel, and a yellow channel that refuses to unclog. You've mixed your own inks by hand (using, say, Paul Roark's C6 base; see below for details) at some approximate dilutions. And you are using an exotic paper, not even designed for inkjet. QTTK's tools will allow you to make that a workable scenario.


## Philosophy

The development of these tools came out of a over a decade's work with the quadtone process, and a great deal of thinking about how these tools fit into the printmaking process.  From my experience, I came up with a short list of guiding principles (inspired by Christopher Alexander's *Pattern Language*) to serve as a basis for developing this software.

  - Make tools, not products: Any craftsman has a set of tools which are optimized for specific uses, yet work together to solve a wide variety of problems. Having access to the right tools allows the printmaker to attain the same results as prepackaged, point-and-click software, or to indeed rise above those results. Therefore, design a decent set of tools that can be used in many ways. Further, design tools so they can be augmented or modified as needed.
  
  - Encourage understanding of process: Much of the modern digital printing process is hidden beneath layers of abstraction and automation. This often denies the possibility of understanding how things really work. True craftsmanship relies on an understanding of materials, processes, and tools. Therefore, as much as possible, show the workings of the process, so they can be both understood and expanded.
  
  - Apply scientific principles: Most digital printmakers use materials and equipment that are extraordinarily accurate (printers, computers, ink, paper), with results that are repeatable and measurable. Yet existing printmaking tools either discourage measurement at all (presuming that all situations are identical) or go about it using repetitive, error-prone manual methods. Therefore, encourage measurement and analysis (along with understanding of that analysis) at all points of the process.
  
  - Allow craft & expressiveness: Art lies partly in vision, and partly in process. An artist must be able to work symbiotically with a process, experimenting with materials and observing reactions, and adjusting to those observations. A process that discourages experimentation or adjustments, or whose tedium results in an artist giving up on experimentation, will result in poorer art. Therefore, provide tools for experimentation, measurement, analysis, and production which encourage the highest level of craft.


## Example usage

There is a single binary command installed, called **qt**.  This binary has several subcommands, referred to here as 'tools'.  Here are a few examples:
    
    # Add a new printer
    $ qt add-printer Quad4000-C6

    # Make a directory for a new profile
    mkdir GenericMatte
    cd GenericMatte
    
    # Initialize the new profile for a given printer
    $ qt init GenericMatte Quad4000-C6
    
    # Print the characterization target, and measure using spectrophotometer
    # (print 'characterization.reference.tif' using QTR calibration mode, measure using MeasureTool, save as 'characterization.measured.txt')
    
    # Characterize the profile based on the measured data; also install as QTR curve
    $ qt characterize

    # Print the linearization target, and measure using spectrophotometer
    # (print 'linearization.reference.tif' using QTR curve, measure using MeasureTool, save as 'linearization.measured.txt')
    
    # Linearize the profile based on the measured data; also install as QTR curve
    $ qt linearize

    # Read image.jpg and create grayscale channel separations, based on existing curve (outputs montaged separations to image.tif)
    $ qt separate /Library/Printers/QTR/quadtone/Quad4000-C6/GenericMatte.quad --montage image.jpg
  

## Installation

Prerequisites:

- Mac OS X (10.6 or later)
- Ruby (1.9.2 or later)
- [ImageMagick](http://www.imagemagick.org) (6.7 or later)
- Various Ruby modules (see `qttk.gemspec` for latest requirements, but generally these will be installed automatically)
- [Quadtone RIP](http://www.quadtonerip.com)
- an inkjet printer supported by QTR (see [QTR requirements](http://www.quadtonerip.com/html/QTRrequire.html)), loaded with several gray shades of ink
- an EyeOne (i1) spectrophotometer (other devices, perhaps including flatbed scanners, to be supported in the future)

I highly suggest that you install Ruby using [RVM](https://rvm.beginrescueend.com/) and ImageMagick using [Brew](https://github.com/mxcl/homebrew).

Once the above packages are present, install QTTR by typing:

    $ gem install quadtone

QTTK has been developed and tested under Mac OS X Lion (10.7).  While it is in the development phase, QTTK is not designed or guaranteed to be usable on any other versions of OS X, or indeed any other systems.


## Further information and resources

- Roy Harrington's [QuadtoneRIP](http://www.quadtonerip.com) (QTR) is a shareware ($50) grayscale RIP system.  For Windows, it is a standalone application; for OS X, it is installed as a set of printer drivers.  QTR comes with a vast number of prebuilt profiles for many Epson printers with several major inksets.

- Paul Roark has a wonderful and extremely useful library of [Digital Black & White Printing Information](http://www.paulroark.com/BW-Info/).  His work on 'homebrewed' carbon inkjet inks (see <http://www.paulroark.com/BW-Info/Ink-Mixing.pdf>) is particularly valuable to me, and will be for any aspiring printmaker.

- Jon Cone and his associates have been pioneers in quadtone inkjet printing.  Their [Piezography](http://piezography.com) system has gone through several incarnations, and was where I started quadtone printing with the now-antique Epson 1160.  Although they now utilize QTR as their software, they use a proprietary method of generating much smoother curves.  They also sell their own quadtone inks, in a variety of tones and channels.

- [MIS](http://www.inksupply.com/bwpage.cfm) (aka InkSupply.com) is one of the primarily distributors of quadtone-capable inks.  They sell a variety of inks in both pre-packaged cartridges for many Epson printers, as well as bulk bottles so you can refill or mix your own.  The black pure-carbon pigment product [Eboni-6 (K)](http://www.inksupply.com/product-details.cfm?pn=UT-HEXPT-K) is the usual starting point for most homebrewing printmakers.  With that, plus the ingredients for Paul Roark's C6 base, you'll be making your own inks and, hopefully, profiling them with QTTK.