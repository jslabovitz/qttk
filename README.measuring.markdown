# How to measure a printed target


## Before measuring

- Let the profile dry completely at room temperature, or use a hair dryer, microwave oven, or surface heater to dry more quickly.

- Place several (2-3) sheets of paper of the same type as the printed target on your workspace, with the printed target on top. (This ensures that the workspace color will not affect the readings.)


## MeasureTool

MeasureTool is a part of the ProfileMaker software package, which may be downloaded from <http://www.xrite.com/product_overview.aspx?ID=757&Action=support&SoftwareID=931>.  While the full package requires a paid license to run, parts of MeasureTool will run in "demo" mode, which is enough to measure a target.

  - connect the spectrophotometer (IMPORTANT that this is done first)
  - launch the **MeasureTool** application (in /Applications/ProfileMaker Pro 5.0.10/MeasureTool)
  - click *Tools* menu and select *Test Chart Measurement...*
  - click *Open...* button
  - select target description file (*.txt)
  - click *Start* button
  - calibrate spectro as instructed
  - click *Mode* popup and select *Strip without gaps*
  - select *Low chart resolution*, especially if print resolution is low (eg, 720 or even 1440)
  - for each strip:
    - align strip reader so start/end is in white areas on left/right side of strip (avoid text labels)
    - place spectro in white area at start of strip
    - press spectro button and hold until strip is read
    - wait ~1s before sliding spectro (to let white area be fully read)
    - slide spectro across strip, slow & steady (should take ~5s to reach end)
    - keep spectro on white area at end for ~1s
    - let go of button
    - should hear single beep for success, or three beeps for failure
  - click *Close* button
  - click *Export Lab...* button
  - save as target measurement file (*.txt)
  - (no need to save any further measurement file)
  
## ColorPort

ColorPort may be downloaded from <http://www.xrite.com/product_overview.aspx?ID=719&Action=support&SoftwareID=1032>.

NOTE: Unfortunately, ColorPort doesn't seem to be able to import our target reference descriptions, perhaps due to subtle format differences.  For now, use MeasureTool.