# TODO


## Now

- Detect & remove bad ink:
  - Too much deviation in samples.
  - Ink limit too low.
- Scale gray values in profile by ink limits?
- Verify limiting/separation algorithms.
  - Generate sample data.
  - Write tests to verify operations.
- Remove hardcoded/assumptions (eg, inks, paper sizes).


## Soon

- Let test targets cross multiple pages:
  - Calculate rows per page.
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
  - Show test images:
    - Radial gradient (stepped, smooth)
    - Linear gradient (stepped, smooth)
    - Charts for final curves?
  - If multiple test results exist:
    - Graph change of lineazation, dMax, color, etc.
- Investigate using RVG (outputting JPEG files) instead of SVG (if so, remove 'builder' dependency).
- Investigate using pre-linearization of individual channels.
- Create smoother curves (using bsplines?).
- Display densities using log scale?


## Later

- Test/rewrite 'add-printer':
  - Use CupsFFI instead of shelling out to 'lpadmin', etc.?
- Move gemspec out of Rakefile and into .gemspec
  - see: http://timelessrepo.com/use-the-gemspec
- Make Target & Sample classes more generic:
  - Limit color knowledge to grayscale, RGB, and Lab.
  - Rename Sample class to Target::Sample.
- Create guide for process (on wiki).
- Document classes & methods.
- Generate our own QTR curves.
- Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.
- Figure out why ColorPort fails to read our reference target file.
