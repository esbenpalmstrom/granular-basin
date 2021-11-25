import Granular
import JLD2
import PyPlot
import Dates

id = "simulation500"    # id of simulation to load, just write the folder
                        # name here

# Layer interface positions
# defined as decimals
# ex: [0.4,0.6,1] will give two boundaries at 0.4 from the bottom
# and 0.6 from the bottom. ie 3 layers
# include 1 in the end as roof.
interfaces = [0,0.4,0.6,1]

# mechanical properties for each layer
youngs_modulus = [2e7,2e7,2e7]              # elastic modulus
poissons_ratio = [0.185,0.185,0.185]        # shear stiffness ratio
tensile_strength = [0.3,0.05,0.3]            # strength of bonds between grains
contact_dynamic_friction = [0.4,0.4,0.4]    # friction between grains
rotating = [true,true,true]                 # can grains rotate or not
color = [0,0,0]

carpet_youngs_modulus = 2e7
carpet_poissons_ratio = 0.185
carpet_tensile_strength = Inf
carpet_contact_dynamic_friction = 0.4
carpet_rotating = true

sim = Granular.readSimulation("$(id)/comp.jld2")
carpet = Granular.readSimulation("$(id)/carpet.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

Granular.zeroKinematics!(sim)       # end any movement
Granular.zeroKinematics!(carpet)    # end any movement

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

# quick fix to make the color = 1 flag for grains belonging to the carpet.
# this should be done in the newer versions of init_basin.jl instead
"""
for grain in sim.grains
    if grain.lin_pos[2] == -0.05
        grain.color = 1
    end
end
"""

h = y_top-y_bot #depth of basin

interfaces *= h

for grain in sim.grains

    for i = 2:size(interfaces,1)

        if grain.lin_pos[2] <= interfaces[i] && grain.lin_pos[2] > interfaces[i-1] && grain.color != 1

            grain.youngs_modulus = youngs_modulus[i-1]
            grain.poissons_ratio = poissons_ratio[i-1]
            grain.tensile_strength = tensile_strength[i-1]
            grain.contact_dynamic_friction = contact_dynamic_friction[i-1]
            grain.rotating = rotating[i-1]
            grain.color = color[i-1]
        elseif grain.color == 1
            grain.youngs_modulus = carpet_youngs_modulus
            grain.poissons_ratio = carpet_poissons_ratio
            grain.tensile_strength = carpet_tensile_strength
            grain.contact_dynamic_friction = carpet_contact_dynamic_friction
            grain.rotating = carpet_rotating
        end
    end
end

# Create the contacs between grains by expanding all grains by a small amount
# then search and establish contacts and then reduce the size of the grains again

size_increasing_factor = 1.10   # factor by which contact radius should be increased
                                # to search for contacts
increase_array = []

#increase the contact radius
for grain in sim.grains
    if grain.color == 0
        contact_radius_increase = (grain.contact_radius*size_increasing_factor)-grain.contact_radius
        grain.contact_radius += contact_radius_increase
        append!(increase_array,contact_radius_increase)
    elseif grain.color == 1
        append!(increase_array,0)
    end
end

Granular.findContactsAllToAll!(sim) # find the grain contacts

#reduce the contact radius again
for i = 1:size(sim.grains,1)
    sim.grains[i].contact_radius -= increase_array[i]
end

cd("$id")
sim.id = "layered"

Granular.resetTime!(sim)
Granular.setTotalTime!(sim,0.2)
Granular.run!(sim)

cd("..")

Granular.writeSimulation(sim,
                        filename = "$(id)/layered.jld2")

Granular.writeSimulation(carpet,
                        filename = "$(id)/carpet.jld2")
