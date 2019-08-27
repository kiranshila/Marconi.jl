using Flux
using Plots
using Flux: onehot

# Problem Setup
min_res = 0.2e-3
unitcell_d = 6.2e-3

inputs = round(Int64,unitcell_d/min_res)

data = rand(Bool,inputs^2)
pretty_input = Array(reshape(data,(inputs,inputs)))
heatmap(pretty_input)

model = Chain(Dense(inputs^2,128,σ),Dense(128,64),Dense(64,7))

model(data)
