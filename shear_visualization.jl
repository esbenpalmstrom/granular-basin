include("Granular/src/Granular.jl")
import JLD2



id_nr = 1 # id number of simulation
grain_nr = 1000 # number of grains in simulation

sim = Granular.readSimulation("simulation$(grain_nr)/deformed$(id_nr).jld2")

SimSettings = JLD2.load("simulation$(grain_nr)/SimSettings.jld2")

r_max = SimSettings["r_max"]




for grain_i in sim.grains
    shear_strain = zeros(2)

    for grain_j in sim.grains
        dx = grain_j.lin_po[1] - grain_i.lin_pos[1]
        dy = grain_j.lin_po[2] - grain_i.lin_pos[2]

        if (dx > r_max*2 || dy > r_max*2 || grain_i==grain_j):
            continue
        end

        disp_x = grain_j.lin_disp[1] - grain_i.lin_disp[1]
        disp_y = grain_j.lin_disp[2] - grain_i.lin_disp[2]

        shear_strain[1] += disp_y/dx
        shear_strain[2] += disp_x/dy

    end
    grain_i.shear_strain = shear_strain
end

Granular.writeVTK(sim,
                  folder = "simulation$(grain_nr)/deformed$(id_nr)_shear_strain")
