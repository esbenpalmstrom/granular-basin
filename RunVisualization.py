import GranularVisualization as GV

imagegrains = GV.importSimulation('simulation40000',18,False)

ColoringArray = 'Color [-]'
#ColoringArray could be any of the strings in imagegrains.PointArrayStatus


#GV.writePVFigure(imagegrains,ColoringArray,timestep = 0.0)
GV.writePVFigure(imagegrains,timestep = 199.0)
