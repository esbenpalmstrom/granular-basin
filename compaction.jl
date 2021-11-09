import Granular
import JLD2
import PyPlot
import Dates

sim = Granular.readSimulation("stacked60k.jld2")
SimSettings = JLD2.load("SimSettings.jld2")

N = 20e3
SimSettings["N"] = N

JLD2.save("SimSettings.jld2", SimSettings)

t_comp = 10.0 #compaction max duration [s]

sim.id = "compaction-N$(N)Pa"

Granular.zeroKinematics!(sim)

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

filen = 1
t_start = Dates.now()


while sim.time < sim.time_total

    for i = 1:100 #run for a while before measuring the state of the top wall
        Granular.run!(sim, single_step=true)
    end

    #Granular.writeSimulation(sim,filename = "compaction-N$(N)Pa/comp$(filen).jld2")
    filen = filen+1

    append!(time, sim.time)
    append!(compaction, sim.walls[1].pos)
    append!(effective_normal_stress, Granular.getWallNormalStress(sim))

    t_now = Dates.now()
    dur = Dates.canonicalize(t_now-t_start)
    print("Time elapsed: ",dur)
end

defined_normal_stress = ones(length(effective_normal_stress)) *
    Granular.getWallNormalStress(sim, stress_type="effective")

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

Granular.writeSimulation(sim,filename = "comp.jld2")
