import Granular
import JLD2
import PyPlot
import Dates

id = "simulation1000"    # id of simulation to load, just write the folder
                        # name here

# Layer interface positions
# defined as decimals
# ex: [0.4,0.6,1] will give two boundaries at 0.4 from the bottom
# and 0.6 from the bottom. ie 3 layers
# include 1 in the end as roof.
interfaces = [0,0.4,0.6,1]

# mechanical properties for each layer
youngs_modulus = [2e7,2e7,2e7]              # elastic modulus
poissons_ratio = [0.185,0.200,0.185]        # shear stiffness ratio
tensile_strength = [0.0,0.0,0.0]            # strength of bonds between grains
contact_dynamic_friction = [0.4,0.4,0.4]    # friction between grains
rotating = [true,true,true]                 # can grains rotate or not

#mechanical properties for carpet
carpet_youngs_modulus = 2e7                 # elastic modulus
carpet_poissons_ratio = 0.185               # shear stiffness ratio
carpet_tensile_strength = Inf               # strength of bonds between grains
carpet_contact_dynamic_friction = 0.4       # friction between grains
carpet_rotating = true                      # can grains rotate or not

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

h = y_top-y_bot

for grain in sim.grains

    for i = 2:size(interfaces,1)

        if grain.lin_pos[2] <= interfaces[i] && grain.lin_pos[2] > interfaces[i-1]

            grain.youngs_modulus = youngs_modulus[i-1]
            grain.poissons_ratio = poissons_ratio[i-1]
            grain.tensile_strength = tensile_strength[i-1]
            grain.contact_dynamic_friction = contact_dynamic_friction[i-1]
            grain.rotating = rotating[i-1]

        end

    end

end

#set the mechanical settings for the carpet
for grain in carpet.grains
    grain.youngs_modulus = carpet_youngs_modulus
    grain.poissons_ratio = carpet_poissons_ratio
    grain.tensile_strength = carpet_tensile_strength
    grain.contact_dynamic_friction = carpet_contact_dynamic_friction
    grain.rotating = carpet_rotating
end


cd("$id")
sim.id = "layered"

Granular.resetTime!(sim)
Granular.setTotalTime!(sim,0.05)
Granular.run!(sim)

cd("..")


Granular.writeSimulation(sim,
                        filename = "$(id)/layered.jld2")

Granular.writeSimulation(carpet,
                        filename = "$(id)/carpet.jld2")
