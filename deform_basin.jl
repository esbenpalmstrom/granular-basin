import Granular
import JLD2
import Dates

t_start = Dates.now()

# User defined settings

id = "simulation250"   # folder name of simulation

hw_ratio = 0.2          # height/width ratio of indenter
grain_radius = 0.05     # grain radius of grains in indenter

deformation_type = "shortening" # "diapir" or "shortening"
                                # diapir will only introduce an indenter while
                                # inversion will also add moving east/west walls
                                # that follow the contraction of the carpet

t_start = Dates.now()

sim = Granular.readSimulation("$(id)/layered.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

for grain in sim.grains
    grain.enabled = true
    grain.fixed = false
end

y_bot_pre = Inf
for grain in sim.grains
    if y_bot_pre > grain.lin_pos[2] - grain.contact_radius
        global y_bot_pre = grain.lin_pos[2] - grain.contact_radius
    end
end

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

y_bot = Inf
for grain in sim.grains
    if y_bot > grain.lin_pos[2] - grain.contact_radius
        global y_bot = grain.lin_pos[2] - grain.contact_radius
    end
end
Granular.setTotalTime!(sim,2.0)
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, .01)
Granular.resetTime!(sim)

cd("$id")
sim.id = "deformed"
sim.walls = Granular.WallLinearFrictionless[] # remove existing walls

#find the edge grains of the carpet
left_edge = -Inf
right_edge = Inf
for i = 1:size(sim.grains,1)
    if left_edge < sim.grains[i].lin_pos[1] + sim.grains[i].contact_radius
        global left_edge = sim.grains[i].lin_pos[1] + sim.grains[i].contact_radius
        left_edge_index = deepcopy(i)
    end
    if right_edge >sim.grains[i].lin_pos[1] - sim.grains[i].contact_radius
        global right_edge = sim.grains[i].lin_pos[1] - sim.grains[i].contact_radius
        right_edge_index = deepcopy(i)
    end
end

#add walls to the east and west
Granular.addWallLinearFrictionless!(sim,[1.,0.],
                                    left_edge,
                                    bc = "fixed")

Granular.addWallLinearFrictionless!(sim,[1.,0.],
                                    right_edge,
                                    bc = "fixed")

#add wall beneath the carpet

Granular.addWallLinearFrictionless!(sim, [0.,1.],
                                    y_bot_pre,
                                    bc = "fixed")



while sim.time < sim.time_total
#    for grain in sim.grains
#
#        if grain.lin_vel[2] < 0 && grain.color == 1
#            grain.lin_vel[2] = 0
#        end
#    end
    Granular.run!(sim,single_step = true)

end

# Granular.resetTime!(sim)
# Granular.setTotalTime!(sim,2.0)
# Granular.run!(sim)

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/deformed.jld2")

#print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
