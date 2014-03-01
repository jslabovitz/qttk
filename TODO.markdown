# TODO

***

  new process (* = user action)
    
    1. initialize
      
      - get profile name from current directory
      - get printer name from argument, or use default
      - get PPD/etc. for printer
      - get inks for printer
      - modify inks from arguments
      
      % qt init [--printer=Quad-C6] [--inks=-M]
      
    2. characterize
      
      a. print characterization target
        
        - generate characterization target for selected printer's ink channels
          - one curve per channel, value on 0..1 scale
          - one column per channel
          - for each row:
            - solid patch of given value (for spot reading)
            - patch with small rectangle of given value inside larger rectangle of maximum value (like current ink limits chart)
            - solid patch of given value, with thin white lines
            
        - print characterization target
          - in calibration mode
        
        % qt characterize
        % qt print ...
      
      b. user examines printed target
      
        - looks for overall ink quality
        - finds patches with maximum density
        - ignores unneeded channels
        
      c. measure characterization target
      
        - map patch IDs from arguments to patches
        - measure spots (using 'spotread')
        - map patches to per-channel ink-limit value
        - channels with no patches specified are disabled
        - save ink limits as L*a*b
        - calculate ink order
        - create curveset for enabled channels
          - apply ink-limits
        
        % qt characterize <patch-1> <patch-2> ...
    
    3. profile
    
      - generate QTR profile
      - install QTR profile
      
    4. linearize (either per channel or composite grayscale)
      
      a. print linearization target
      
        - generate linearization target
          - create curveset for color model
          - if per-channel:
            - apply ink limits
          - generate .tiX files for chartread
          - generate target image
          
        % qt linearize { --raw | --composite> }
        % qt print [--calibrate] <target-file>
        
      b. measure linearization target      
      
    5. test
    
      a. print test target
      
      b. measure test target
        
        - save test results
    
    6. visualize
    
      - ink order, color
      - ink limits
      - overall linearization (color, error)
      - density range
      - QTR curves
      - channel separations for a given image
    
***

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
  - Make all Color classes have component/value structure.
    - Rename 'channel' to 'component'.
    - Remove need for explicit knowledge of class (eg, in Profile#read_samples!: "case sample.input ... when Color::QTR").

- Improve target generation:
  - Add info banner to target:
    - Mode (characterization, linearization, etc.)
    - Date
    - Profile info (printer, paper, inks)

- Improve analysis:
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
  - Optionally normalize curves in charts.
  - Represent a/b for measured (L*a*b) colors.
  - Parameterize error threshold.
  - Show individual sample points.
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

- Create guide for process (on wiki).

- Document classes & methods.

- Bypass QTR entirely
  - Use Gutenprint to generate DeviceN or ESC/P2 files.