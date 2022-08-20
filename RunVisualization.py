import GranularVisualization as GV

imagegrains = GV.importSimulation('simulation40000',20,False)

ColoringArray = 'Color [-]'
GV.writePVFigure(imagegrains,ColoringArray)
