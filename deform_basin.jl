import Granular
import JLD2
import Dates


# User defined settings

id = "simulation1000"   # folder name of simulation

hw_ratio = 0.2          # height/width ratio of indenter
grain_radius = 0.05     # grain radius of grains in indenter

deformation_type = # "diapir" or "inversion"

t_start = Dates.now()

sim = Granular.readSimulation("$(id)/comp.jld2")
carpet = Granular.readSimulation("$(id)/carpet.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

temp_indent = createSimulation("id=temp_indent")
