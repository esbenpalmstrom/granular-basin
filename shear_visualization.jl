include("Granular/src/Granular.jl")
import JLD2
import Statistics

id_nr = 1 # id number of simulation
grain_nr = 1000 # number of grains in simulation

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

    global k = 1

    for grain_j in sim.grains
        dx = grain_j.lin_pos[1] - grain_i.lin_pos[1]
        dy = grain_j.lin_pos[2] - grain_i.lin_pos[2]
        dist = sqrt((dx^2)+(dy^2))

        #if (dx > (r_av*2) || dy > (r_av*2) || grain_i==grain_j)
        if (dist > r_av*3 || grain_i == grain_j || grain_j.color == -1 || grain_j.color == 0
             || dist < (r_av/2) || dx < grain_i.areal_radius*0.1  || dy < grain_i.areal_radius*0.1)
            continue
        end

        @info "accepted dist: $(dist), this is number $(j), and it is number $(k) contact for this grain"
        global j += 1
        global k += 1

        disp_x = grain_j.lin_disp[1] - grain_i.lin_disp[1]
        disp_y = grain_j.lin_disp[2] - grain_i.lin_disp[2]

        shear_strain[1] += disp_y/dx
        shear_strain[2] += disp_x/dy

        if (shear_strain[1] > 100 || shear_strain[2] > 100)
            @warn "shear strain of over 100 was detected for grain $(i), with disp_x of $(disp_x) and disp_y of $(disp_y)
            and dx of $(dx) and dy of $(dy)"
        end

    end

    shear_strain_array[:,i] = shear_strain

    if (grain_i.color == 0 || grain_i.color == -1)
        shear_strain_array[:,i] = [0.0,0.0]
    end




    global i+=1

end

maxstrain = maximum(shear_strain_array)

@info "max shear strain: $(maxstrain)
        average: $(Statistics.mean(shear_strain_array))"


Granular.writeVTK(sim,
                  folder = "simulation$(grain_nr)/deformed$(id_nr)_shear_strain",
                  shear_strain_matrix=shear_strain_array)
