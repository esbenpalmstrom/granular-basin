"""
This script will initialize a granular basin.

Settings for this script should be adjusted in the top of the script before running
Feel free to implement commandline argument parsing or whatever else.

A local copy of the Granular package is included, since changes were made to the
source code to accomodate certain functionalities.

The files init_basin.jl, compact_basin.jl and deform_basin.jl should all be run
from the same directory.

Relevant arguments:
* `t_init::Float64=5.0`: Time to spend initializing the first stack of the basin [s].
* `t_stack::Float64=2.0`: Time to let each subsequent stack settle [s].
* `g::Vector{Float64}=[0.,-9.8]`: gravitational acceleration vector [m/s^2].
* `ngrains::Int`: Approximate number of grains to include in the simulation.
* `aspect_ratio::Int=6`: Approximate final width to height ratio of the basin.
    A ratio of 6 will give a basin which is approximately 6 times as wide as it is deep.
* `stacks::Int=2`: Number of times that the grains should be stacked on top of
    themselves during the initialization. Has no influence on final number of
    grains. This is done only for computation time purposes.
* `r_min::Float64=0.05`: Minimum radius of grains [m]. The maximum radius of
    grains will be calculated to make the largest grains have twice the area
    of the smallest. This can be changed in the script.
* `gsd_type::String="powerlaw"`: Type of grain size distribution. Can be
    "powerlaw" or "uniform".
* `gsd_power_exponent::Float64=-1.8`: Exponent if powerlaw is used for grain
    size distribution
* `gsd_seed::Int`: Seed for random distribution of grain sizes.
* `youngs_modulus::Float64=2e7`: Youngs modulus for initial grains [Pa].
    Will be changed later.
* `poissons_ratio::Float64=0.185`: Poissons ratio for the initial grains.
    Will be changed later.
* `tensile:strength::Float64=0.0`: Tensile bond strength for inital grains [Pa].
    Will be changed later.
* `contact_dynamic_friction::Float64=0.4`: Coulomb frictional coefficient.
    Will be changed later
* `rotating::Bool=true`: Whether grains should be allowed to rotate or not.

"""

include("Granular/src/Granular.jl")
import JLD2
import Dates

t_start = Dates.now()           # Save the start time, print the end time later.

############# Initialization Settings #############

t_init = 5.0                    # duration of initialization [s]
t_stack = 2.0                   # duration for each stack to settle [s]

g = [0.,-9.8]                   # vector for direction and magnitude of gravitational acceleration of grains

ngrains = 3000                  # total number of grains
aspect_ratio = 4                # should be x times as wide as it is tall, 6 is used for the 40k experiment

mkpath("simulation$(ngrains)")

stacks = 2                           # number of duplicate stacks on top of the initial grains

ny = sqrt((ngrains)/aspect_ratio)    # number of grain rows
nx = aspect_ratio*ny*(stacks+1)      # number of grain columns

ny = Int(round(ny/(stacks+1)))
nx = Int(round(nx/(stacks+1)))

r_min = 0.05                    # minimum radius of grains
r_max = r_min*sqrt(2)           # max radius of grains, double the area of minimum

# Grain-size distribution parameters
gsd_type = "powerlaw"           # type grain-size distribution
gsd_powerlaw_exponent = -1.8    # exponent if powerlaw is used for grain-size distribution
gsd_seed = 3                    # random seed for the distribution of grain-sizes

# Initial mechanical properties of grains
youngs_modulus = 2e7            # elastic modulus
poissons_ratio = 0.185          # shear stiffness ratio
tensile_strength = 0.0          # strength of bonds between grains
contact_dynamic_friction = 0.4  # friction between grains
rotating = true                 # can grains rotate or not

# Save some settings in a dictionary for use in other scripts.
SimSettings = Dict()
SimSettings["nx"] = nx
SimSettings["ny"] = ny
SimSettings["stacks"] = stacks
SimSettings["ngrains"] = ngrains
SimSettings["r_min"] = r_min
SimSettings["r_max"] = r_max

############# Initialize simulation and grains #############

sim = Granular.createSimulation(id="simulation$(ngrains)")

Granular.regularPacking!(sim,                   #simulation object
                        [nx, ny],               #number of grains along x and y axis
                        r_min,                  #smallest grain size
                        r_max,                  #largest grain size
                        tiling="triangular",    #how the grains are tiled
                        origo = [0.0,0.0],
                        size_distribution=gsd_type,
                        size_distribution_parameter=gsd_powerlaw_exponent,
                        seed=gsd_seed)


# set the indicated mechanical parameters for all grains
for grain in sim.grains
    grain.youngs_modulus = youngs_modulus
    grain.poissons_ratio = poissons_ratio
    grain.tensile_strength = tensile_strength
    grain.contact_dynamic_friction = contact_dynamic_friction
    grain.rotating = rotating
	grain.color = 1
end

# fit the ocean grid to the grains
Granular.fitGridToGrains!(sim, sim.ocean)

# set the boundary conditions
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
                                    verbose=false)
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "east west",
                                    verbose=false)

# add gravity to the grains and remove ocean drag
for grain in sim.grains
    Granular.addBodyForce!(grain, grain.mass*g)
    Granular.disableOceanDrag!(grain)
    grain.contact_viscosity_normal = 1e4  # N/(m/s)
end

# run the simulation
Granular.setTimeStep!(sim)                  # set appropriate time steps
Granular.setTotalTime!(sim, t_init)         # set total time
Granular.setOutputFileInterval!(sim, .01)   # how often vtu files should be outputted

cd("simulation$(ngrains)")

sim.id = "init"

Granular.run!(sim)


############# Stack the initialized grains #############

temp = deepcopy(sim)

for i = 1:stacks

    # find the position of the uppermost grain
    global y_top = -Inf

    for grain in sim.grains
        if y_top < grain.lin_pos[2]
            global y_top = grain.lin_pos[2]
        end
    end

    # add duplicate grains above the initialized grains
    for grain in temp.grains

        lin_pos_lifted = [0.0,0.0]                              # preallocation of position of a 'lifted' grain
        lin_pos_lifted[1] = grain.lin_pos[1]                    # x position of duplicate grain
        lin_pos_lifted[2] = grain.lin_pos[2] + y_top + r_max    # y-position of duplicate grain


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


    # instead of Granular.resetTime!(sim), the time parameters are reset manually, in order
    # to allow for the continuation of vtu-file index from earlier
    sim.time_iteration = 0
    sim.time = 0.0
    sim.file_time_since_output_file = 0.

    Granular.setTotalTime!(sim, t_stack)
    Granular.setTimeStep!(sim)
    Granular.setOutputFileInterval!(sim, .01)

    Granular.run!(sim)  # let the duplicated grains settle.

end


############# Lay a carpet #############

carpet = Granular.createSimulation(id="init_carpet") # new simulation object for the carpet

bot_r = r_min # radius of carpet grains

left_edge = round(sim.ocean.origo[1],digits=2)  # west edge of the carpet
length = round(sim.ocean.L[1],digits=2)         # width of the carpet
right_edge = left_edge+length                   # east edge of the carpet


# Now loop over the carpet grain positions, the loop will create grains that overlap slightly
# in order to create the bonds needed
# color = 0 is used as a flag for the grains in the carpet
for i = left_edge+(bot_r/2):bot_r*1.999:left_edge+length

    bot_pos = [i,round(sim.ocean.origo[2]-bot_r,digits=2)] # position of grain

    Granular.addGrainCylindrical!(carpet,
                                bot_pos,
                                bot_r,
                                0.1,
                                verbose = false,
                                tensile_strength = Inf,
                                shear_strength = Inf,
                                fixed = false,
                                color = 0)
end



Granular.findContactsAllToAll!(carpet) # find the grain contacts


append!(sim.grains,carpet.grains) # add the carpet grains to the main simulation object



#reset the grain contacts and make them very old

"""
for grain in sim.grains
    grain.contacts[:] .= 0
    grain.n_contacts = 0
end


for grain in sim.grains
	for ic=1:size(grain.contact_age,1)
		grain.contact_age[ic] = 1e16
	end
    grain.strength_heal_rate = 1 # new bond stengthening
end
"""

Granular.fitGridToGrains!(sim,sim.ocean,verbose=false)  # fit the ocean to the added grains

Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
																verbose=false)
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "east west",
																verbose=false)

# run the simulation shortly, to let the stacked grains settle on the carpet
sim.time_iteration = 0
sim.time = 0.0
sim.file_time_since_output_file = 0.
Granular.setTotalTime!(sim, 0.5)
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, .01)

Granular.run!(sim)


# save the simulation and the carpet objects
cd("..")

Granular.writeSimulation(sim,
                        filename = "simulation$(ngrains)/init.jld2")

JLD2.save("simulation$(ngrains)/SimSettings.jld2", SimSettings)

# print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
