import Granular
import JLD2
import PyPlot
import Dates

include("indent.jl")

#call this script as "@elapsed include("initialization.jl")" in order to time it

t_start = Dates.now()

t_init = 0.5 # duration of initialization [s]
t_stack = 0.4 #duration for each stacking

g = [0.,-9.8]

nx = 25 #125
ny = 8 #80
stacks = 0

ngrains = nx*ny*(stacks+1)

suffix = "_test"

r_min = 0.05
r_max = r_min*sqrt(2) #max grain size is double area of smallest grain size

SimSettings = Dict()

SimSettings["nx"] = nx
SimSettings["ny"] = ny
SimSettings["r_min"] = r_min
SimSettings["r_max"] = r_max

#JLD2.save("SimSettings$(ngrains)$(suffix).jld2", SimSettings)

gsd_type = "powerlaw"
gsd_powerlaw_exponent = -1.8
gsd_seed = 3

# mechanical properties of grains
youngs_modulus = 2e7            #elastic modulus
poissons_ratio = 0.185          #shear stiffness ratio
tensile_strength = 0.0          #strength of bonds between grains
contact_dynamic_friction = 0.4  #friction between grains
rotating = true                 #can grains rotate or not

sim = Granular.createSimulation(id="init")
sim.id = "init$(ngrains)$(suffix)"

Granular.regularPacking!(sim,       #simulation object
                        [nx, ny],   #number of grains along x and y axis
                        r_min,      #smallest grain size
                        r_max,      #largest grain size
                        tiling="triangular", #how the grains are tiled
                        origo = [0.0,0.0],
                        size_distribution=gsd_type,
                        size_distribution_parameter=gsd_powerlaw_exponent,
                        seed=gsd_seed)

for grain in sim.grains #go through all grains in sim
    grain.youngs_modulus = youngs_modulus
    grain.poissons_ratio = poissons_ratio
    grain.tensile_strength = tensile_strength
    grain.contact_dynamic_friction = contact_dynamic_friction
    grain.rotating = rotating
end

Granular.fitGridToGrains!(sim, sim.ocean)

Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
                                    verbose=false)
#Granular.setGridBoundaryConditions!(sim.ocean, "periodic", "east west")
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "east west")


for grain in sim.grains
    Granular.addBodyForce!(grain, grain.mass*g)
    Granular.disableOceanDrag!(grain)
    grain.contact_viscosity_normal = 1e4  # N/(m/s)
end

Granular.setTimeStep!(sim)

Granular.setTotalTime!(sim, t_init)

Granular.setOutputFileInterval!(sim, .01)

Granular.run!(sim)

#Granular.writeSimulation(sim,
#                        filename = "init$(ngrains)$(suffix).jld2",
#                        folder = "init$(ngrains)$(suffix)")

#Stack it on top of each other

temp = deepcopy(sim)

for i = 1:stacks

    global y_top = -Inf
    for grain in sim.grains
        if y_top < grain.lin_pos[2] #+ grain.contact_radius
            global y_top = grain.lin_pos[2] #+ grain.contact_radius
        end
    end


    for grain in temp.grains

        lin_pos_lifted = [0.0,0.0]

        lin_pos_lifted[1] = grain.lin_pos[1]
        lin_pos_lifted[2] = grain.lin_pos[2] + y_top + r_max


        Granular.addGrainCylindrical!(sim,
                                    lin_pos_lifted,
                                    grain.contact_radius,
                                    grain.thickness,
                                    youngs_modulus = grain.youngs_modulus,
                                    poissons_ratio = grain.poissons_ratio,
                                    tensile_strength = grain.tensile_strength,
                                    contact_dynamic_friction = grain.contact_dynamic_friction,
                                    verbose = false)

    end

    Granular.fitGridToGrains!(sim,sim.ocean,verbose=false)
    Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
                                                                    verbose=false)
    Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "east west",
                                                                    verbose=false)
    Granular.setTotalTime!(sim,t_stack)
    Granular.setTimeStep!(sim)
    Granular.setOutputFileInterval!(sim, .01)

    for grain in sim.grains
        Granular.addBodyForce!(grain, grain.mass*g)
        Granular.disableOceanDrag!(grain)
    end

    #Granular.resetTime!(sim)
    sim.time_iteration = 0
    sim.time = 0.0
    sim.file_time_since_output_file = 0.

    Granular.setTotalTime!(sim, t_stack)
    Granular.setTimeStep!(sim)
    Granular.setOutputFileInterval!(sim, .01)

    Granular.run!(sim)

end

# add a lower boundary consisting of grains bound together
# do this by creating a new simulation where the grains are bonded using
# findContacts! after creating overlapping grains. Then set their contact
# strengths to an infinite amount, but do not allow new contacts

carpet = Granular.createSimulation(id="init_carpet")

bot_r = r_min #radius of bottom layer grains

left_edge = round(sim.ocean.origo[1],digits=2)
length = round(sim.ocean.L[1],digits=2)
right_edge = left_edge+length

for i = left_edge+(bot_r/2):bot_r*1.99:left_edge+length

    bot_pos = [i,round(sim.ocean.origo[2]-bot_r,digits=2)]

    Granular.addGrainCylindrical!(carpet,
                                bot_pos,
                                bot_r,
                                0.1,
                                verbose = false,
                                tensile_strength = Inf,
                                shear_strength = Inf,
                                contact_stiffness_normal = Inf,
                                contact_stiffness_tangential = Inf)

end

Granular.findContactsAllToAll!(carpet) #find the grain contacts

#carpet.grains[10].fixed = true
#carpet.grains[10].lin_vel[1:2] = [0.0,0.0]


#add the carpet to the main simulation object
append!(sim.grains,carpet.grains)


#fit the ocean to the added grains and run to let the basin settle

Granular.fitGridToGrains!(sim,sim.ocean,verbose=false)

Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
                                    verbose=false)

sim.time_iteration = 0
sim.time = 0.0
sim.file_time_since_output_file = 0.
Granular.setTotalTime!(sim, 0.2)
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, .01)

Granular.run!(sim)

Granular.writeSimulation(sim,
                        filename = "stacked$(ngrains)$(suffix).jld2")

########## Add indenter #############

temp_indent = createSimulation("id=temp_indent")


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
Granular.setTotalTime!(sim, 0.5)
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, .01)

while sim.time < sim.time_total
    for grain in carpet.grains
        if grain.lin_vel[2] < 0 #&& grain.lin_pos[2] < r_min #find some lower boundary here?
            grain.lin_vel[1:2] = [0.,0.]
        end
    end
    Granular.run!(sim,single_step=true)
end

Granular.writeSimulation(sim,
                        filename = "indented$(ngrains)_test.jld2")


#print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
