include("Granular/src/Granular.jl")
import JLD2
import Dates
import PyPlot
using ArgParse

t_start = Dates.now()


function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin

        "simulation_id"
            help = "number identifier of the simulation. fx. 1, 2, 3 or 4"
            arg_type = Int
            required = true
        "sim_nr"
            help = "the number identifying the simulation, usually close to the number of grains the simulation"
            arg_type = Int
            #required = true
            default = 600
        "hw_ratio"
            help = "height to width ratio of the indeter. Ratio of 0.2 would make height 20% of the width"
            arg_type = Float64
            #required = true
            default = 0.12
        "def_time"
            help = "Time to stretch the deformation phase over. Shorter deformation time will give faster deformation"
            arg_type = Float64
            #required = true
            default = 10.00
        "shortening"
            help = "Shortening with side walls can be turned on of off (true/false)"
            arg_type = Bool
            #required = true
            default = true
        "shortening_type"
            help = "Type of shortening. 'Fixed' will make the walls move in with constant given velocity"
            arg_type = String
            #required = true
            default = "fixed"
        "shortening_ratio"
            help = "The amount of shortening of the basin. 0.05 will give a 5% shortening by the end of the deformation phase"
            arg_type = Float64
            #required = true
            default = 0.05
        "boomerang_end_pos"
            help = "End position of the indenter relative to the height of the basin, 0.2 will make the indenter move up 20% of the height of the basin.Set to 0.0 if you want no inversion."
            arg_type = Float64
            #required = true
            default = 0.20
        "weak_bot"
            help = "Bottom decimal position of the weak layer"
            arg_type = Float64
            default = 0.4
        "weak_top"
            help = "Top decimal position of the weak layer"
            arg_type = Float64
            default = 0.6
        "strong_youngs_modulus"
            help = "YM of the strong layer"
            arg_type = Float64
            default = 2e7
        "weak_youngs_modulus"
            help = "YM of the weak layer"
            arg_type = Float64
            default = 2e7
        "strong_poissons_ratio"
            help = "PR of the strong layer"
            arg_type = Float64
            default = 0.185
        "weak_poissons_ratio"
            help = "PR of the weak layer"
            arg_type = Float64
            default = 0.185
        "strong_tensile_strength"
            help = "Tensile strength of the strong layer"
            arg_type = Float64
            default = 0.3
        "weak_tensile_strength"
            help = "Tensile strength of the weak layer"
            arg_type = Float64
            default = 0.01
        "strong_shear_strength"
            help = "Shear strength of the strong layer"
            arg_type = Float64
            default = 0.3
        "weak_shear_strength"
            help = "Tensile strength of the weak layer"
            arg_type = Float64
            default = 0.01
        "strong_contact_dynamic_friction"
            help = "Friction coefficient of grains in strong layer"
            arg_type = Float64
            default = 0.4
        "weak_contact_dynamic_friction"
            help = "Friction coefficient of grains in the weak layer"
            arg_type = Float64
            default = 0.1
        "strong_color"
            help = "Color coding of grains in the strong layer"
            arg_type = Int
            default = 1
        "weak_color"
            help = "Color coding of grains in the weak layer"
            arg_type = Int
            default = 2
        "t_rest"
            help = "Time for the basin to rest after layering but before the deformation phase."
            arg_type = Float64
            default = 5.0
        "strong_density"
            help = "Density of the strong layer"
            arg_type = Float64
            default = 934.0
        "weak_density"
            help = "Density of the weak layer"
            arg_type = Float64
            default = 934.0

    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    println("Parsed args:")
    for (arg,val) in parsed_args
        println("  $arg  =>  $val")
    end
end

main()

parsed_args = parse_commandline()


#unpack the dict containing parsed args
sim_nr = parsed_args["sim_nr"]
hw_ratio = parsed_args["hw_ratio"]
def_time = parsed_args["def_time"]
shortening = parsed_args["shortening"]
shortening_type = parsed_args["shortening_type"]
shortening_ratio = parsed_args["shortening_ratio"]
boomerang_end_pos = parsed_args["boomerang_end_pos"]
interfaces = [0.0,parsed_args["weak_bot"],parsed_args["weak_top"],1.0]
youngs_modulus = [parsed_args["strong_youngs_modulus"],parsed_args["weak_youngs_modulus"],parsed_args["strong_youngs_modulus"]]
poissons_ratio = [parsed_args["strong_poissons_ratio"],parsed_args["weak_poissons_ratio"],parsed_args["strong_poissons_ratio"]]
tensile_strength = [parsed_args["strong_tensile_strength"],parsed_args["weak_tensile_strength"],parsed_args["strong_tensile_strength"]]
shear_strength = [parsed_args["strong_shear_strength"],parsed_args["weak_shear_strength"],parsed_args["strong_shear_strength"]]
contact_dynamic_friction = [parsed_args["strong_contact_dynamic_friction"],parsed_args["weak_contact_dynamic_friction"],parsed_args["strong_contact_dynamic_friction"]]
color = [parsed_args["strong_color"],parsed_args["weak_color"],parsed_args["strong_color"]]
t_rest = parsed_args["t_rest"]
density = [parsed_args["strong_density"],parsed_args["weak_density"],parsed_args["strong_density"]]
id_number = parsed_args["simulation_id"]

id = "simulation$(sim_nr)"

# ************************ Layering phase ************************

sim = Granular.readSimulation("$(id)/comp.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

# quick fix to color everything except the carpet as color = 1
# for some older initiated assemblies, this needs to be done
for grain in sim.grains
    if grain.lin_pos[2] != -0.05
        grain.color = 1
    end
end

y_top = -Inf
for grain in sim.grains
    grain.contact_viscosity_normal = 0
    if y_top < grain.lin_pos[2] + grain.contact_radius
        global y_top = grain.lin_pos[2] + grain.contact_radius
    end
end

y_bot = Inf
for grain in sim.grains
    if y_bot > grain.lin_pos[2] - grain.contact_radius
        global y_bot = grain.lin_pos[2] - grain.contact_radius
    end
end


#Create a color layering scheme that respect the geological layers

color_interfaces = collect(range(0,1,length=11))


h = y_top-y_bot
color_interfaces = collect(range(0,1,length=16))*h
colors = [10,20,10,20,10,20,10,20,10,20,10,20,10,20,10,20]
interfaces *= h


for grain in sim.grains

    for i = 2:size(interfaces,1)

        if grain.lin_pos[2] <= interfaces[i] && grain.lin_pos[2] > interfaces[i-1] && grain.color != 0

            grain.youngs_modulus = youngs_modulus[i-1]
            grain.poissons_ratio = poissons_ratio[i-1]
            grain.tensile_strength = tensile_strength[i-1]
            grain.shear_strength = shear_strength[i-1]
            grain.contact_dynamic_friction = contact_dynamic_friction[i-1]
            grain.color = color[i-1]

        end
    end
end

for grain in sim.grains

    for j = 2:size(color_interfaces,1)

        if grain.lin_pos[2] <= color_interfaces[j] && grain.lin_pos[2] > color_interfaces[j-1] && grain.color != 0

            grain.color += colors[j-1]

        end
    end
end





# Create the bonds between grains by expanding all grains by a small amount
# then search and establish contacts and then reduce the size of the grains again

size_increasing_factor = 1.10   # factor by which contact radius should be increased
                                # to search for contacts
size_reduction_factor = -((size_increasing_factor-1)/(1+(size_increasing_factor-1)))
increase_array = []

#increase the contact radius
for grain in sim.grains
    if grain.color != 0
        contact_radius_increase = (grain.contact_radius*size_increasing_factor)-grain.contact_radius
        grain.contact_radius += contact_radius_increase
        append!(increase_array,contact_radius_increase)
    elseif grain.color == 0
        append!(increase_array,0)
    end
end

Granular.findContacts!(sim,method="ocean grid")
#Granular.findContactsAllToAll!(sim) # find the grain contacts
#Granular.run!(sim,single_step=true)

#reduce the contact radius again
#for i = 1:size(sim.grains,1)
#    sim.grains[i].contact_radius -= increase_array[i]
#end
for grain in sim.grains
    if grain.color != 0
        grain.contact_radius = grain.contact_radius + grain.contact_radius*size_reduction_factor
    end
end


cd("$id")


save_type = "iterative"

#if save_type == "iterative"
#    global save_index = 1
#    while isdir("layered$(save_index)") == true
#        global save_index += 1
#    end
#    sim.id = "layered$(save_index)"
#end
sim.id = "layered$(id_number)"



Granular.resetTime!(sim)
Granular.setTotalTime!(sim,t_rest)

Granular.run!(sim)

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/layered$(id_number).jld2")





# ************************ Deformation phase ************************



#sim = Granular.readSimulation("$(id)/layered$(save_index).jld2")



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

y_top = -Inf
for grain in sim.grains
    #grain.contact_viscosity_normal = 0
    if y_top < grain.lin_pos[2] + grain.contact_radius
        global y_top = grain.lin_pos[2] + grain.contact_radius
    end
end

# Add Indenter
temp_indent = Granular.createSimulation("id=temp_indent")

left_edge = round(sim.ocean.origo[1],digits=2)
length = round(sim.ocean.L[1],digits=2)

#width = length/3
width = length*(4/6)

init_vertex_pos = [(length+left_edge)/2,y_bot_pre-0.2]
grain_radius = SimSettings["r_min"]

vertex_x = init_vertex_pos[1]
#vertex_y = width*hw_ratio*sin((pi/width)*vertex_x)
vertex_y = init_vertex_pos[2]

boomerang_vel = ((y_top-vertex_y)*boomerang_end_pos)/def_time

@info "The indenter will have a velocity of $(boomerang_vel) m/s"

for i = 0:grain_radius*2:width

    x_pos = i

    y_pos = width*hw_ratio*sin(pi/width*x_pos)

    Granular.addGrainCylindrical!(temp_indent,
                                    [x_pos+init_vertex_pos[1]-width/2,y_pos-(width*hw_ratio)+init_vertex_pos[2]],
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

sim.id = "deformed$(id_number)"


#sim.walls = Granular.WallLinearFrictionless[] # remove existing walls

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

        if shortening_type == "fixed" && checked_done == false #add conditional to only start shortening when indenter deforms?
            wall_vel = (length*shortening_ratio)/sim.time_total
            sim.walls[1].vel = -wall_vel/2
            sim.walls[2].vel = wall_vel/2
            global checked_done = true
            @info "The shortening walls will have a velocity of $(wall_vel) m/s"
        end
    end

    Granular.run!(sim,single_step = true)

end

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/deformed$(id_number).jld2")

#print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
