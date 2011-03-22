# TODO


## Now

- Fix linearization problem: why is max of 21-step scale different than max of actual samples?
- Find better name for project.
- Move info in 'README.measuring.markdown' to wiki.
- Remove hardcoded/assumptions from 'profile' tool (eg, 'data' directory, paper sizes).
- Create profile description file (profile.yaml?) to store profile-related metadata.
  - Use $PRINTER, but only for initial creation.
- Correctly scale normalized curves (for charts).
- Verify limiting/separation algorithms.
- Create guide for process (on wiki).


## Soon

- Document classes.
- Determine if it's possible to only need one QTR calibration target (wide scale with unlimited inks).
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


## Later

- Document methods.
- Refactor QuadCurves to use CurveSet instead of its own curve data.
- Replace use of external Color class with our own.
  - Use density throughout instead of luminance.
- Generate our own QTR curves.
- Use Jones diagrams for showing data <http://en.wikipedia.org/wiki/Jones_diagram>.