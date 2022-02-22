include("Granular/src/Granular.jl")
import JLD2
import Statistics

id_nr = 10 # id number of simulation
grain_nr = 40000 # number of grains in simulation

@info "Started shear calculations for simulation $(id_nr) containing $(grain_nr) grains"

sim = Granular.readSimulation("simulation$(grain_nr)/deformed$(id_nr).jld2")

SimSettings = JLD2.load("simulation$(grain_nr)/SimSettings.jld2")

r_max = SimSettings["r_max"]
r_min = SimSettings["r_min"]
r_av = (r_max+r_min)/2



global shear_strain_array = zeros(2,size(sim.grains,1))

global i = 1

global j = 0

global k = 1

for grain_i in sim.grains
    shear_strain = zeros(2)

    #global k = 1

    for grain_j in sim.grains
        dx = grain_j.lin_pos[1] - grain_i.lin_pos[1]
        dy = grain_j.lin_pos[2] - grain_i.lin_pos[2]
        dist = sqrt((dx^2)+(dy^2))

        #if (dx > (r_av*2) || dy > (r_av*2) || grain_i==grain_j)
        if (dist > r_av*5 || grain_i == grain_j || grain_j.color == -1 || grain_j.color == 0
             || dx < grain_i.areal_radius*0.1  || dy < grain_i.areal_radius*0.1)
            continue
        end


        disp_x = grain_j.lin_disp[1] - grain_i.lin_disp[1]
        disp_y = grain_j.lin_disp[2] - grain_i.lin_disp[2]

        shear_strain[1] += disp_y/dx
        shear_strain[2] += disp_x/dy


    end

    shear_strain_array[:,i] = shear_strain

    if (grain_i.color == 0 || grain_i.color == -1)
        shear_strain_array[:,i] = [0.0,0.0]
    end

    global i+=1

    if (i%1000 == 0)
        @info "Progress: $(i)/$(size(sim.grains,1))"
    end

end

maxstrain = maximum(shear_strain_array)

@info "max shear strain: $(maxstrain)
        average: $(Statistics.mean(shear_strain_array))"


Granular.writeVTK(sim,
                  folder = "simulation$(grain_nr)/deformed$(id_nr)_shear_strain",
                  shear_strain_matrix=shear_strain_array)
