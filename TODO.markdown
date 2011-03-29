# TODO


## Now

- Remove hardcoded/assumptions (eg, inks, paper sizes).
- Verify limiting/separation algorithms.


## Soon

- Add option to normalize curves in charts.
- Create guide for process (on wiki).
- Document classes.
 - Add confirmation/testing step to profiling:
  - Show actual tonal response curve.
  - Show dMin/dMax.
  - Show Lab curve (eg, ink color).
  - If multiple test results exist:
    - Graph change of lineazation, dMax, color, etc.
- Investigate using RVG (outputting JPEG files) instead of SVG (if so, remove 'builder' dependency).
- Investigate using pre-linearization of individual channels.
- Create smoother curves (using bsplines?).
- Display densities using log scale?
- Test/rewrite 'add-printer':
  - Use CupsFFI instead of shelling out to 'lpadmin', etc.?
- Figure out why ColorPort fails to read our reference target file.
- Move gemspec out of Rakefile and into .gemspec
  - see: http://timelessrepo.com/use-the-gemspec

## Later

- Document methods.
- Refactor QuadCurves to use CurveSet instead of its own curve data.
- Replace use of external Color class with our own.
  - Use density throughout instead of luminance?
- Generate our own QTR curves.
- Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.