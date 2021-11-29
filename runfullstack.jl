import Dates
stack_t_start = Dates.now()

include("init_basin.jl")
include("compact_basin.jl")
include("layer_basin.jl")
include("deform_basin.jl")

stack_t_now = Dates.now()
stack_dur = Dates.canonicalize(stack_t_now-stack_t_start)
print("Total full stack time elapsed: ",stack_dur)
