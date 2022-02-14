include("Granular/src/Granular.jl")
import JLD2
import PyPlot
import Dates

t_start = Dates.now() # Save the start time, print the end time later.


id = "simulation1000"  # id of simulation to load
N = 20e3                # amount of stress to be applied
t_comp = 5.0            # compaction max duration [s]
t_rest = 2.0

sim = Granular.readSimulation("$(id)/init.jld2")
SimSettings = JLD2.load("$(id)/SimSettings.jld2")
#sim = Granular.readSimulation("$(id)/comp.jld2") #use this if continuing already finished compaction

ngrains = SimSettings["ngrains"]

cd("$id")
sim.id = "compaction-N$(N)Pa"
SimSettings["N"] = N


Granular.zeroKinematics!(sim)

y_top = -Inf
for grain in sim.grains
    grain.contact_viscosity_normal = 0
    if y_top < grain.lin_pos[2] + grain.contact_radius
        global y_top = grain.lin_pos[2] + grain.contact_radius
    end
end

#sim.walls = Granular.WallLinearFrictionless[] # remove existing walls, if already compacted some.

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

#fixed_thickness = 2. * SimSettings["r_max"]
#for grain in sim.grains
#    if grain.lin_pos[2] <= fixed_thickness
#        grain.fixed = true  # set x and y acceleration to zero
#    end
#end

Granular.resetTime!(sim)

Granular.setTotalTime!(sim,t_comp)

time = Float64[]
compaction = Float64[]
effective_normal_stress = Float64[]

saved5sec = false
saved10sec = false


while sim.time < sim.time_total

    for i = 1:100 # run for a while before measuring the state of the top wall
        Granular.run!(sim, single_step=true)
    end

    if sim.time > 5.0 && saved5sec == false
        Granular.writeSimulation(sim,filename = "comp5sec.jld2")
        global saved5sec = true
    end

    if sim.time > 10.0 && saved10sec == false
        Granular.writeSimulation(sim,filename = "comp10sec.jld2")
        global saved10sec = true
    end

    append!(time, sim.time)
    append!(compaction, sim.walls[1].pos)
    append!(effective_normal_stress, Granular.getWallNormalStress(sim))

end




defined_normal_stress = ones(size(effective_normal_stress,1)) *
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


#remove the wall and let the basin rest for a couple of seconds
sim.walls = Granular.WallLinearFrictionless[] # remove existing walls

sim.time_iteration = 0
sim.time = 0.0
sim.file_time_since_output_file = 0.
Granular.setTotalTime!(sim,t_rest)

Granular.run!(sim)

cd("..")



JLD2.save("simulation$(ngrains)/SimSettings.jld2", SimSettings)

Granular.writeSimulation(sim,filename = "$(id)/comp.jld2")

#Granular.writeSimulation(sim,filename = "$(id)/comp10sec.jld2")

# print time elapsed
t_now = Dates.now()
dur = Dates.canonicalize(t_now-t_start)
print("Time elapsed: ",dur)
