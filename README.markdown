# Quadtone Toolkit (QTTK)

QTTK provides a set of tools for printmakers who use the quadtone inkjet printing process.  It works in conjunction with the [QuadtoneRIP](http://www.quadtonerip.com) (QTR) grayscale printing system.

At the moment, the software consists largely of libraries of code (written in the [Ruby](http://ruby-lang.org) programming language) and a single command-line tool.  Hence, it is probably not interesting to most printmakers unless they are either programmers or people comfortable with the Unix command line.  Additionally, printmakers who are happy with Epson's "automatic black and white" mode, the default QTR profiles, or the [Piezography](http://piezography.com) system can probably feel comfortable in moving on.

However, if you are interested in printing on obscure papers, hand-mixing your own inks, or otherwise want more control and knowledge over the printmaking process, these tools may help.  I originally wrote them because I was dissatisfied with the perception of the quadtone process being "black magic," inaccessible, or unscientific.  It is my hope that tools like QTTK will increase the understanding and acceptance of the quadtone inkjet process.

At some point, given sufficient interest and motivation, I may write a graphical interface (GUI) to the underlying code.  In the meantime, please enjoy the art and craft of the [Unix command line](http://en.wikipedia.org/wiki/Command-line_interface).


## Capabilities

QTTK enables you to:

  - Generate profiling targets to be printed and analyzed.  Many parameters can be set, including paper size, color mode (either QTR calibration or grayscale), ink channels, ink limits, and patch oversampling rates.  In addition to an image file (TIFF), a reference data file is also generated, which can be used by MeasureTool or other color profiling systems.
  
  - Analyze measurements of printed reference targets.  Individual ink channels are detected, as well as tonal response curves, maximum-density points, and other data.  Grayscale ink separations can be easily calculated, as well as linearization curves for grayscale targets.
  
  - Create visual charts and graphs of analyzed information, including response curves and density scales.
  
  - Build and install QTR profiles, based on measured data, avoiding complex and error-prone manual calculations.
  
  - Preview how images will print through particular QTR profiles, actually separating a grayscale image into the ink channels as represented in the the QTR curve files.


## Example usage

There is a single binary command installed, called **qt**.  This binary has several subcommands, referred to here as 'tools'.  Here are a few examples:

    # Go through the process of making a new profile for a given printer
    $ qt profile GenericMatte Quad4000-C6
  
    # Read image.jpg and create grayscale channel separations, based on existing curve (outputs montaged separations to image.tif)
    $ qt separate /Library/Printers/QTR/quadtone/Quad4000-C6/GenericMatte.quad --montage image.jpg
  
    # Add a new printer
    $ qt add-printer Quad4000-C6


## Installation

Prerequisites:

- Mac OS X (10.6 or later)
- Ruby (1.9.2 or later)
- External libraries: [GNU Scientific Library](http://www.gnu.org/software/gsl/), [ImageMagick](http://www.imagemagick.org)
- Various Ruby modules (see `Rakefile` for latest requirements, but generally these will be installed automatically)
- [Quadtone RIP](http://www.quadtonerip.com)
- an inkjet printer supported by QTR (see [QTR requirements](http://www.quadtonerip.com/html/QTRrequire.html))

I highly suggest that you install Ruby, GSL, and ImageMagick using either [Brew](https://github.com/mxcl/homebrew) or [MacPorts](http://macports.org).

Once the above packages are present, install QTTR by simply typing:

    $ gem install quadtone

QTTK has been developed and tested under Mac OS X Snow Leopard (10.6).  While it is in the development phase, QTTK is not designed or guaranteed to be usable on any other versions of OS X, or indeed any other systems.


## Further information and resources

- Roy Harrington's [QuadtoneRIP](http://www.quadtonerip.com) (QTR) is a shareware ($50) grayscale RIP system.  For Windows, it is a standalone application; for OS X, it is installed as a set of printer drivers.  QTR comes with a vast number of prebuilt profiles for many Epson printers with several major inksets.

- Paul Roark has a wonderful and extremely useful library of [Digital Black & White Printing Information](http://www.paulroark.com/BW-Info/).  His work on "homebrewed" carbon inkjet inks (see <http://www.paulroark.com/BW-Info/Ink-Mixing.pdf>) is particularly valuable to me, and will be for any aspiring printmaker.

- Jon Cone and his associates have been pioneers in quadtone inkjet printing.  Their [Piezography](http://piezography.com) system has gone through several incarnations, and was where I started quadtone printing with the now-antique Epson 1160.  Although they now utilize QTR as their software, they use a proprietary method of generating much smoother curves.  They also sell their own quadtone inks, in a variety of tones and channels.

- [MIS](http://www.inksupply.com/bwpage.cfm) (aka InkSupply.com) is one of the primarily distributors of quadtone-capable inks.  They sell a variety of inks in both pre-packaged cartridges for many Epson printers, as well as bulk bottles so you can refill or mix your own.  The black pure-carbon pigment product [Eboni-6 (K)](http://www.inksupply.com/product-details.cfm?pn=UT-HEXPT-K) is the usual starting point for most homebrewing printmakers.  With that, plus the ingredients for Paul Roark's "C6" base, you'll be making your own inks and, hopefully, profiling them with QTTK.