#!/bin/sh

julia deform_basin.jl 16 40000 0.12 10.0 false "fixed" 0.0 0.5 0.0 0.5 3.5e7 0.5e7 0.185 0.300 0.7 0.01 0.7 0.01 0.25 0.05 1 2 5.0 934.0 934.0 "simple" false

julia deform_basin.jl 17 40000 0.12 10.0 false "fixed" 0.0 0.5 0.0 0.5 3.0e7 0.5e7 0.185 0.300 0.8 0.01 0.8 0.01 0.2 0.05 1 2 5.0 934.0 934.0 "simple" false

julia deform_basin.jl 18 40000 0.12 10.0 false "fixed" 0.1 0.5 0.0 0.5 3.0e7 0.5e7 0.185 0.300 0.8 0.01 0.8 0.01 0.2 0.05 1 2 5.0 934.0 934.0 "simple" false

julia deform_basin.jl 19 40000 0.12 10.0 false "fixed" 0.0 0.5 0.0 0.5 3.5e7 0.5e7 0.185 0.300 0.7 0.01 0.7 0.01 0.2 0.05 1 2 5.0 934.0 934.0 "custom" false

julia deform_basin.jl 20 40000 0.12 10.0 false "fixed" 0.1 0.5 0.0 0.5 3.5e7 0.5e7 0.185 0.300 0.7 0.01 0.7 0.01 0.2 0.05 1 2 5.0 934.0 934.0 "custom" false

julia deform_basin.jl 3 3000 0.12 10.0 false "fixed" 0.10 0.5 0.0 0.5 3.5e7 0.5e7 0.185 0.300 0.7 0.01 0.7 0.01 0.0 0.0 1 2 1.0 934.0 934.0 "simple" false
