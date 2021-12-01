import Granular
import JLD2
import Dates

t_start = Dates.now()

# User defined settings

id = "simulation500"   # folder name of simulation

hw_ratio = 0.2          # height/width ratio of indenter
grain_radius = 0.05     # grain radius of grains in indenter
def_time = 2.0         # time spent deforming

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

boomerang_vel = 0.5 # upward velocity of the indeter

for i = 0:grain_radius*2:width#manipulate the ocean grid

    x_pos = i

    y_pos = width*hw_ratio*sin(pi/width*x_pos)

    Granular.addGrainCylindrical!(temp_indent,
                                    [x_pos+init_vertex_pos[1]-width/2,y_pos+vertex_y+init_vertex_pos[2]],
                                    grain_radius,
                                    0.1,
                                    fixed = true,
                                    lin_vel = [0.0,boomerang_vel],
                                    color = -1)
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
Granular.setTotalTime!(sim,def_time)
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
        global left_edge_index = deepcopy(i)
    end
    if right_edge > sim.grains[i].lin_pos[1] - sim.grains[i].contact_radius
        global right_edge = sim.grains[i].lin_pos[1] - sim.grains[i].contact_radius
        global right_edge_index = deepcopy(i)
    end
end

"""
carpet_index = []
# find the center grain of the carpet
for i = 1:size(sim.grains,1)
    if sim.grains[i].color == 0
        append!(carpet_index,i)
    end
end
c_i = size(carpet_index)/2
"""


#add walls to the east and west
Granular.addWallLinearFrictionless!(sim,[1.,0.],
                                    left_edge,
                                    bc = "velocity")

Granular.addWallLinearFrictionless!(sim,[1.,0.],
                                    right_edge,
                                    bc = "velocity")

#add wall beneath the carpet

Granular.addWallLinearFrictionless!(sim, [0.,1.],
                                    y_bot_pre,
                                    bc = "fixed")




global checked_done = false

#sim.walls[1].vel = -boomerang_vel
#sim.walls[2].vel = boomerang_vel

while sim.time < sim.time_total

    if sim.grains[right_edge_index].lin_vel[1] > boomerang_vel/3 && checked_done == false
        sim.walls[1].vel = -boomerang_vel
        sim.walls[2].vel = boomerang_vel
        global checked_done = true
    end

    #sim.walls[1].vel = sim.grains[left_edge_index].lin_vel[1]
    #sim.walls[2].vel = sim.grains[right_edge_index].lin_vel[1]

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
