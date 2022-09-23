# designed to be run in the PV integrated IDLE to test if it works

import glob
import os
import re
natsort = lambda s: [int(t) if t.isdigit() else t.lower() for t in re.split('(\d+)', s)]

timestep = 199.0

os.chdir('/Users/esben/github/granular-basin')

pathvtu = 'simulation40000/deformed18/*.vtu'
listvtu = glob.glob(pathvtu)

listvtu.sort(key=natsort)
imagegrains = XMLUnstructuredGridReader(FileName=listvtu) #pass .vtu file list here

imagegrains.PointArrayStatus = [
'Density [kg m^-3]',
'Thickness [m]',
'Diameter (contact) [m]',
'Diameter (areal) [m]',
'Circumreference  [m]',
'Horizontal surface area [m^2]',
'Side surface area [m^2]',
'Volume [m^3]',
'Mass [kg]',
'Moment of inertia [kg m^2]',
'Linear velocity [m s^-1]',
'Linear acceleration [m s^-2]',
'Sum of forces [N]',
'Linear displacement [m]',
'Angular position [rad]',
'Angular velocity [rad s^-1]',
'Angular acceleration [rad s^-2]',
'Sum of torques [N*m]',
'Fixed in space [-]',
'Fixed but allow (x) acceleration [-]',
'Fixed but allow (y) acceleration [-]',
'Fixed but allow (z) acceleration [-]',
'Free to rotate [-]',
'Enabled [-]',
'Contact stiffness (normal) [N m^-1]',
'Contact stiffness (tangential) [N m^-1]',
'Contact viscosity (normal) [N m^-1 s]',
'Contact viscosity (tangential) [N m^-1 s]',
'Contact friction (static) [-]',
'Contact friction (dynamic) [-]',
"Young's modulus [Pa]",
"Poisson's ratio [-]",
'Tensile strength [Pa]'
'Shear strength [Pa]'
'Strength heal rate [Pa/s]'
'Compressive strength prefactor [m^0.5 Pa]',
'Ocean drag coefficient (vertical) [-]',
'Ocean drag coefficient (horizontal) [-]',
'Atmosphere drag coefficient (vertical) [-]',
'Atmosphere drag coefficient (horizontal) [-]',
'Contact pressure [Pa]',
'Number of contacts [-]',
'Granular stress [Pa]',
'Ocean stress [Pa]',
'Atmosphere stress [Pa]',
'Color [-]']

#inputs: imagegrains, timeslice, color1, color2

renderView1 = GetActiveViewOrCreate('RenderView')
# uncomment following to set a specific view size
renderView1.ViewSize = [2478, 1570]
imagegrainsDisplay = Show(imagegrains, renderView1)

imagegrainsDisplay.Representation = 'Surface'
imagegrainsDisplay.AmbientColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.ColorArrayName = [None, '']
imagegrainsDisplay.OSPRayScaleArray = 'Angular acceleration [rad s^-2]'
imagegrainsDisplay.OSPRayScaleFunction = 'PiecewiseFunction'
imagegrainsDisplay.SelectOrientationVectors = 'Angular acceleration [rad s^-2]'
imagegrainsDisplay.ScaleFactor = 6.050000000000001
imagegrainsDisplay.SelectScaleArray = 'Diameter (areal) [m]'
imagegrainsDisplay.GlyphType = 'Sphere'
imagegrainsDisplay.GlyphTableIndexArray = 'Angular acceleration [rad s^-2]'
imagegrainsDisplay.DataAxesGrid = 'GridAxesRepresentation'
imagegrainsDisplay.PolarAxes = 'PolarAxesRepresentation'
imagegrainsDisplay.ScalarOpacityUnitDistance = 64.20669746996803
imagegrainsDisplay.GaussianRadius = 3.0250000000000004
imagegrainsDisplay.SetScaleArray = ['POINTS', 'Diameter (areal) [m]']
imagegrainsDisplay.ScaleTransferFunction = 'PiecewiseFunction'
imagegrainsDisplay.OpacityArray = ['POINTS', 'Atmosphere drag coefficient (horizontal) [-]']
imagegrainsDisplay.OpacityTransferFunction = 'PiecewiseFunction'

# init the 'GridAxesRepresentation' selected for 'DataAxesGrid'
imagegrainsDisplay.DataAxesGrid.XTitleColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.YTitleColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.ZTitleColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.GridColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.XLabelColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.YLabelColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.DataAxesGrid.ZLabelColor = [0.0, 0.0, 0.0]

# init the 'PolarAxesRepresentation' selected for 'PolarAxes'
imagegrainsDisplay.PolarAxes.PolarAxisTitleColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.PolarAxes.PolarAxisLabelColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.PolarAxes.LastRadialAxisTextColor = [0.0, 0.0, 0.0]
imagegrainsDisplay.PolarAxes.SecondaryRadialAxesTextColor = [0.0, 0.0, 0.0]

# reset view to fit data
renderView1.ResetCamera()

#changing interaction mode based on data extents
renderView1.InteractionMode = '2D'

# update the view to ensure updated data information
renderView1.Update()

# create a new 'Glyph'
glyph1 = Glyph(Input=imagegrains,
    GlyphType='Sphere')
glyph1.add_attribute = ['POINTS', 'Atmosphere drag coefficient (horizontal) [-]']
glyph1.add_attribute = ['POINTS', 'Angular acceleration [rad s^-2]']
glyph1.ScaleFactor = 6.050000000000001
glyph1.GlyphTransform = 'Transform2'

# Properties modified on glyph1
glyph1.add_attribute = ['POINTS', 'Diameter (areal) [m]']
glyph1.add_attribute = ['POINTS', 'Angular position [rad]']
glyph1.ScaleFactor = 1.0
glyph1.GlyphMode = 'All Points'

# get color transfer function/color map for 'Diameterarealm'
diameterarealmLUT = GetColorTransferFunction('Diameterarealm')

# show data in view
glyph1Display = Show(glyph1, renderView1)
# trace defaults for the display properties.
glyph1Display.Representation = 'Surface'
glyph1Display.AmbientColor = [0.0, 0.0, 0.0]
#glyph1Display.ColorArrayName = ['POINTS', 'Diameter (areal) [m]']
glyph1Display.ColorArrayName = ['POINTS',ColoringArray]
glyph1Display.LookupTable = diameterarealmLUT
glyph1Display.OSPRayScaleArray = 'Diameter (areal) [m]'
glyph1Display.OSPRayScaleFunction = 'PiecewiseFunction'
glyph1Display.SelectOrientationVectors = 'GlyphVector'
glyph1Display.ScaleFactor = 6.1000000000000005
glyph1Display.SelectScaleArray = 'Diameter (areal) [m]'
glyph1Display.GlyphType = 'Sphere'
glyph1Display.GlyphTableIndexArray = 'Diameter (areal) [m]'
glyph1Display.DataAxesGrid = 'GridAxesRepresentation'
glyph1Display.PolarAxes = 'PolarAxesRepresentation'
glyph1Display.GaussianRadius = 3.0500000000000003
glyph1Display.SetScaleArray = ['POINTS', 'Diameter (areal) [m]']
glyph1Display.ScaleTransferFunction = 'PiecewiseFunction'
glyph1Display.OpacityArray = ['POINTS', 'Diameter (areal) [m]']
glyph1Display.OpacityTransferFunction = 'PiecewiseFunction'

# init the 'GridAxesRepresentation' selected for 'DataAxesGrid'
glyph1Display.DataAxesGrid.XTitleColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.YTitleColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.ZTitleColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.GridColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.XLabelColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.YLabelColor = [0.0, 0.0, 0.0]
glyph1Display.DataAxesGrid.ZLabelColor = [0.0, 0.0, 0.0]

# init the 'PolarAxesRepresentation' selected for 'PolarAxes'
glyph1Display.PolarAxes.PolarAxisTitleColor = [0.0, 0.0, 0.0]
glyph1Display.PolarAxes.PolarAxisLabelColor = [0.0, 0.0, 0.0]
glyph1Display.PolarAxes.LastRadialAxisTextColor = [0.0, 0.0, 0.0]
glyph1Display.PolarAxes.SecondaryRadialAxesTextColor = [0.0, 0.0, 0.0]



# show color bar/color legend
glyph1Display.SetScalarBarVisibility(renderView1, True)

# update the view to ensure updated data information
renderView1.Update()

# reset view to fit data and change to correct timeslice

renderView1.ResetCamera()

# Properties modified on glyph1
glyph1.GlyphType = 'Sphere'
glyph1.ScaleArray = ['Diameter (areal) [m]']

# update the view to ensure updated data information
renderView1.Update()

# hide color bar/color legend
glyph1Display.SetScalarBarVisibility(renderView1, False)

# rescale color and/or opacity maps used to exactly fit the current data range
glyph1Display.RescaleTransferFunctionToDataRange(False, True)

# get opacity transfer function/opacity map for 'Diameterarealm'
diameterarealmPWF = GetOpacityTransferFunction('Diameterarealm')

# Apply a preset using its name. Note this may not work as expected when presets have duplicate names.
#diameterarealmLUT.ApplyPreset('X Ray', True)

# Hide orientation axes
renderView1.OrientationAxesVisibility = 0

# current camera placement for renderView1
renderView1.InteractionMode = '2D'

#change background color to white
renderView1.Background = [1,1,1]

ResetCamera()
renderView1.CameraParallelScale = 20
renderView1.Update()

renderView1.ViewTime = timestep
renderView1.StillRender()
