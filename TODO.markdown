# TODO

- Improve profile initialization:
  - Use CupsFFI instead of 'lpadmin' to determine default printer.
  - Add initial ink-limit to profile/target.
    - To allow for more accurate results on papers known to be very absorbent.
    - From posting on DigitalBW: "Find the limit of the full black ink by watching for
      slight puddling and or printing a pattern with some 1 pixel spaced white lines 
      surrounded by much larger areas of solid black. When the edges of those 1 pixel 
      lines start to get fuzzy, you have too much ink.

  - Allow negation of inks (eg, '-LLK').
  - Find good printer defaults:
    - Medium/high resolution (1440/2880).
    - Unidirectional ("lospeed").
    - Dithering mode ("Ordered")
  - Save *all* printer options to profile (again) so they can be shown/verified.
  - Save curves to profile so they are only generated once (when profiled).

- Improve target generation:
  - Replace current system with Argyll front-end:
    - Generate targets (targen)
    - Montage onto single page (?)
    - Create target image (printtag)
    - Measure target (chartread)
      - Iterate once per ink
      - Calibrate on first pass
  - Add info banner to target:
    - Mode (characterization, linearization, etc.)
    - Date
    - Profile info (printer, paper, inks)

- Improve analysis:
  - Retain individual output samples from measured target
    - Average while making curve (spline)
    - Also use for oversampling when generating target.
  - Experiment with whether more steps or over-sampling is better.
  - Determine optimum delta-E for ink detection (& make configurable).
  - Detect & remove bad ink:
    - Too much deviation in samples.
  - Calculate dot gain.
    - http://www.brucelindbloom.com/index.html?Eqn_DotGain.html
  - Verify limiting/separation algorithms.
    - Generate sample data.
    - Write tests to verify operations.
    - Scale gray values in profile by ink limits?
        http://lists.apple.com/archives/colorsync-users/2007/Jan/msg00379.html
        http://www.colorforums.com/viewtopic.php?t=80
        http://www.onyxtalk.com/thread-understanding-ink-limits
  - Generate our own QTR curves.
    - Pre-linearize of individual channels.
    - Create smoother curves (using bsplines?).
  - Use L* profiling?
    - http://tech.groups.yahoo.com/group/QuadtoneRIP/message/9691
    
- Improve charting:
  - Write HTML file, with embedded graphics (SVG?).
  - Optionally normalize curves in charts.
  - Represent a/b for measured (L*a*b) colors.
  - Parameterize error threshold.
  - Show individual sample points.
  - Investigate using RVG for charts instead of SVG (if so, remove 'builder' dependency).
  - Display densities using log scale?
  - Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.

- Add confirmation/testing step to profiling:
  - To test ink settling, sample fading, etc.
  - Show actual tonal response curve.
  - Show Lab curve (eg, ink color).
  - Show charts for final curves.
  - If multiple test results exist:
    - Graph change of linearization, density range, color, etc.

- Build web interface.
  - Create account.
  - Create new profile.
  - Generate reference/target files.
    - Download as ZIP archive.
  - Upload measured files.
  - Analyze/visualize measurements.
  - Generate QTR profile.
    - Download QTR profile.
  - Maybe small raw-printing utility, in MacRuby?
  - Eventually, curve-builder and installer?

- Test/rewrite 'add-printer':
  - Use CupsFFI instead of shelling out to 'lpadmin', etc.?

- Move gemspec out of Rakefile and into .gemspec
  - see: http://timelessrepo.com/use-the-gemspec

- Create guide for process (on wiki).

- Document classes & methods.

- Bypass QTR entirely
  - Use Gutenprint to generate DeviceN or ESC/P2 files.