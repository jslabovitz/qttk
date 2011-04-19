# TODO

- Figure out why 21x4 target takes up 5 rows.

- Replace Sample with Point.

- Retain individual output samples from measured target
  - Average while making curve (spline)
  - Show individual points in chart.
  
- Submit 'cupsffi' changes to maintainer.
  - Remove hard-coded 'require' of 'cupsffi'.

- Get media page/margins from PPD file for printing target.

- Include test reference image in gem distribution, rather than using something in ~/Downloads.

- Detect & remove bad ink:
  - Too much deviation in samples.
  - Ink limit too low.

- Scale gray values in profile by ink limits?

- Verify limiting/separation algorithms.
  - Generate sample data.
  - Write tests to verify operations.
    http://lists.apple.com/archives/colorsync-users/2007/Jan/msg00379.html

- Remove hardcoded/assumptions (eg, inks, paper sizes).

- Experiment with whether more steps or over-sampling is better.

- Determine optimum delta-E for ink detection (& make configurable).

- Add '--print' option to target generation, so target can be generated & printed in one step.

- Separate generation of target reference file from target image.  Image file should just be generated from reference file.

- Maybe have 'print' tool generate target images?
  - eg: qttk print --target linearization
  - with '--save' option to also write image to file?

- Improve target:
  - Let test targets cross multiple pages:
    - Calculate rows per page.
    - Raise error on too many samples only if can't fit on max number of pages.
  - Add info banner to target:
    - Mode (characterization, linearization, etc.)
    - Date
    - Profile info (printer, paper, inks)

- Add option to normalize curves in charts.

- Add confirmation/testing step to profiling:
  - To test ink settling, sample fading, etc.
  - Show actual tonal response curve.
  - Show dMin/dMax.
  - Show Lab curve (eg, ink color).
  - Show charts for final curves.
  - If multiple test results exist:
    - Graph change of lineazation, dMax, color, etc.

- Investigate using RVG for targets & charts instead of SVG (if so, remove 'builder' dependency).

- Create smoother curves (using bsplines?).

- Display densities using log scale?

- Test/rewrite 'add-printer':
  - Use CupsFFI instead of shelling out to 'lpadmin', etc.?

- Move gemspec out of Rakefile and into .gemspec
  - see: http://timelessrepo.com/use-the-gemspec

- Make Target & Sample classes more generic:
  - Limit color knowledge to grayscale, RGB, and Lab (handle QTR in CurveSet).
  - Rename Sample class to Target::Sample.

- Create guide for process (on wiki).

- Document classes & methods.

- Generate our own QTR curves.
  - Pre-linearize of individual channels.

- Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.

- Figure out why ColorPort fails to read our reference target file.