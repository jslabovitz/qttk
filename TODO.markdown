# TODO

- Improve profile initialization:
  - Use CupsFFI instead of 'lpadmin' to determine default printer.
  - Add initial ink-limit to profile/target.
    - To allow for more accurate results on papers known to be very absorbent.
  - Allow negation of inks (eg, '-LLK').

- Improve target generation:
  - Separate generation of target reference file from target image.
    - Image file should just be generated from reference file.
  - Let test targets cross multiple pages.
  - Add info banner to target:
    - Mode (characterization, linearization, etc.)
    - Date
    - Profile info (printer, paper, inks)
    - Page (n/m).

- Improve analysis:
  - Retain individual output samples from measured target
    - Average while making curve (spline)
    - Also use for oversampling when generating target.
  - Experiment with whether more steps or over-sampling is better.
  - Determine optimum delta-E for ink detection (& make configurable).
  - Detect & remove bad ink:
    - Too much deviation in samples.
    - Ink limit too low.
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
  
- Improve charting:
  - Add option to normalize curves in charts.
  - If Lab color, somehow draw a/b values.
  - Parameterize error threshold.
  - Show individual sample points.
  - Investigate using RVG for charts instead of SVG (if so, remove 'builder' dependency).
  - Display densities using log scale?
  - Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.

- Add confirmation/testing step to profiling:
  - To test ink settling, sample fading, etc.
  - Show actual tonal response curve.
  - Show dMin/dMax.
  - Show Lab curve (eg, ink color).
  - Show charts for final curves.
  - If multiple test results exist:
    - Graph change of lineazation, dMax, color, etc.

- Submit 'cupsffi' changes to maintainer.
  - Remove hard-coded 'require' of 'cupsffi'.

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

- Figure out why ColorPort fails to read our reference target file.

- Generate Argyll-compatible CGATS files:
    targen -d 0 -f 21 foo
    printtarg -i i1 foo
    chartread -n -l -N -B -S foo

- Bypass QTR entirely
  - Use Gutenprint to generate ESC/P2 files.