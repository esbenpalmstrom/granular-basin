import Granular
import JLD2
import PyPlot
import Dates

t_start = Dates.now() # Save the start time, print the end time later.

# lav en lille test? se om dit appendede carpet stadig er forbundet til hoved-
# simulationsobjektet

id = "simulation500"    # id of simulation to load
N = 20e3                # amount of stress to be applied
t_comp = 3.0            # compaction max duration [s]

sim = Granular.readSimulation("$(id)/init.jld2")
carpet = Granular.readSimulation("$(id)/carpet.jld2")
SimSettings = SimSettings = JLD2.load("$(id)/SimSettings.jld2")

#mkpath("$(id)/compaction-N$(N)Pa")

cd("$id")
sim.id = "compaction-N$(N)Pa"
#sim.id = "$(id)/compaction-N$(N)Pa"
SimSettings["N"] = N


Granular.zeroKinematics!(sim)

Granular.zeroKinematics!(carpet)

y_top = -Inf
for grain in sim.grains
    grain.contact_viscosity_normal = 0
    if y_top < grain.lin_pos[2] + grain.contact_radius
        global y_top = grain.lin_pos[2] + grain.contact_radius
    end
end

Granular.addWallLinearFrictionless!(sim, [0., 1.],y_top,
                                    bc="normal stress",
                                    normal_stress=-N,
                                    contact_viscosity_normal=1e3)

Granular.fitGridToGrains!(sim,sim.ocean)

y_bot = Inf
for grain in sim.grains
    if y_bot > grain.lin_pos[2] - grain.contact_radius
        global y_bot = grain.lin_pos[2] - grain.contact_radius
    end
end

fixed_thickness = 2. * SimSettings["r_max"]
for grain in sim.grains
    if grain.lin_pos[2] <= fixed_thickness
        grain.fixed = true  # set x and y acceleration to zero
    end
end

Granular.resetTime!(sim)
Granular.setTotalTime!(sim,t_comp)

time = Float64[]
compaction = Float64[]
effective_normal_stress = Float64[]

while sim.time < sim.time_total

    for i = 1:100 # run for a while before measuring the state of the top wall
        Granular.run!(sim, single_step=true)
    end

    append!(time, sim.time)
    append!(compaction, sim.walls[1].pos)
    append!(effective_normal_stress, Granular.getWallNormalStress(sim))

end

defined_normal_stress = (ones(size(effective_normal_stress,1)))
    *(Granular.getWallNormalStress(sim, stress_type="effective"))

PyPlot.subplot(211)
PyPlot.subplots_adjust(hspace=0.0)
ax1 = PyPlot.gca()
PyPlot.setp(ax1[:get_xticklabels](),visible=false) # Disable x tick labels
PyPlot.plot(time, compaction)
PyPlot.ylabel("Top wall height [m]")
PyPlot.subplot(212, sharex=ax1)
PyPlot.plot(time, defined_normal_stress)
PyPlot.plot(time, effective_normal_stress)
PyPlot.xlabel("Time [s]")
PyPlot.ylabel("Normal stress [Pa]")
PyPlot.savefig(sim.id * "-time_vs_compaction-stress.pdf")
PyPlot.clf()

cd("..")

JLD2.save("simulation$(ngrains)/SimSettings.jld2", SimSettings)

Granular.writeSimulation(sim,filename = "$(id)/comp.jld2")
