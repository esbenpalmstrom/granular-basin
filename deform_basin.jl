import Granular
import JLD2
import Dates


# User defined settings

id = "simulation1000"   # folder name of simulation

hw_ratio = 0.2          # height/width ratio of indenter
grain_radius = 0.05     # grain radius of grains in indenter

deformation_type = "diapir" # "diapir" or "inversion"
                            # diapir will only introduce an indenter while
                            # inversion will also add moving east/west walls
                            # that follow the contraction of the carpet

t_start = Dates.now()

sim = Granular.readSimulation("$(id)/layered.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

# Add Indenter
temp_indent = Granular.createSimulation("id=temp_indent")

left_edge = round(sim.ocean.origo[1],digits=2)
length = round(sim.ocean.L[1],digits=2)

width = length/3
hw_ratio = 0.2
init_vertex_pos = [(length+left_edge)/2,-0.2]
grain_radius = 0.05

vertex_x = init_vertex_pos[1]
vertex_y = width*hw_ratio*sin((pi/width)*vertex_x)


for i = 0:grain_radius*2:width#manipulate the ocean grid

    x_pos = i

    y_pos = width*hw_ratio*sin(pi/width*x_pos)

    Granular.addGrainCylindrical!(temp_indent,
                                    [x_pos+init_vertex_pos[1]-width/2,y_pos+vertex_y+init_vertex_pos[2]],
                                    grain_radius,
                                    0.1,
                                    fixed = true,
                                    lin_vel = [0.0,0.5])
end

append!(sim.grains,temp_indent.grains)

Granular.fitGridToGrains!(sim,
                            sim.ocean,
                            north_padding = 3.0,
                            verbose=false)

sim.time_iteration = 0
sim.time = 0.0
sim.file_time_since_output_file = 0.
Granular.setTotalTime!(sim,2.0)
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, .01)


cd("$id")
sim.id = "deformed"

Granular.resetTime!(sim)
Granular.setTotalTime!(sim,2.0)
Granular.run!(sim)

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/deformed.jld2")
