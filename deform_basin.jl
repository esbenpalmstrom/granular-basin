import Granular
import JLD2
import Dates

t_start = Dates.now()

# User defined settings

id = "simulation500"   # folder name of simulation

hw_ratio = 0.2          # height/width ratio of indenter
def_time = 2.0          # time spent deforming

shortening = true               # true if walls should be introduced. false if only a diapir

shortening_type = "fixed"       # type of shortening should be "iterative" or "fixed"

shortening_ratio = 0.05         # ratio of shortening of of basin, if shortening_type
                                # is "fixed". 0.10 would mean basin is shortened by 10%


save_type = "iterative"         # "iterative" or "overwrite"




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
grain_radius = SimSettings["r_min"]

vertex_x = init_vertex_pos[1]
vertex_y = width*hw_ratio*sin((pi/width)*vertex_x)

boomerang_vel = 0.1 # upward velocity of the indeter

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
                            north_padding = 5.0,
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
if save_type == "overwrite"
    sim.id = "deformed"
end

if save_type == "iterative"
    global save_index = 1
    while isfile("deformed$(save_index).jld2") == true
        global save_index += 1
    end
    sim.id = "deformed$(save_index)"
end


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

    if shortening == true
        if shortening_type == "iterative"
            if sim.grains[right_edge_index].lin_vel[1] > boomerang_vel/2 && checked_done == false
                sim.walls[1].vel = -boomerang_vel
                sim.walls[2].vel = boomerang_vel
                global checked_done = true
            end

            #modulate the speed of the compression walls by the speed of the outer grains
            if abs(sim.walls[2].vel) > boomerang_vel/2 || abs(sim.walls[2].vel) > abs(sim.grains[right_edge_index].lin_vel[1])*0.98
                #if boomerang_vel < abs(sim.grains[right_edge_index].lin_vel[1]) || abs(sim.walls[2].vel) > boomerang_vel
                sim.walls[2].vel *= 0.98
            end
            #if abs(sim.walls[2].vel) < abs(sim.grains[right_edge_index].lin_vel[1])*0.90
            if abs(sim.walls[2].vel) < abs(sim.grains[right_edge_index].lin_vel[1])*0.96
                sim.walls[2].vel *=1.02
            end

            #if boomerang_vel < abs(sim.grains[left_edge_index].lin_vel[1]) || abs(sim.walls[1].vel) > boomerang_vel
            if abs(sim.walls[1].vel) > boomerang_vel/2 || abs(sim.walls[1].vel) > abs(sim.grains[left_edge_index].lin_vel[1])*0.98
                sim.walls[1].vel *= 0.98
            end
            #if abs(sim.walls[1].vel) < abs(sim.grains[left_edge_index].lin_vel[1])*0.90
            if abs(sim.walls[1].vel) < abs(sim.grains[left_edge_index].lin_vel[1])*0.96
                sim.walls[1].vel *=1.02
            end
        end

        if shortening_type == "fixed" && checked_done == false
            wall_vel = (length*shortening_ratio)/sim.time_total
            sim.walls[1].vel = -wall_vel/2
            sim.walls[2].vel = wall_vel/2
            global checked_done = true
        end
    end

    Granular.run!(sim,single_step = true)

end

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/deformed$(save_index).jld2")

#print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
