using Marconi
using PlotlyJS
using BenchmarkTools

AF = generateRectangularAF(2,2,10e-3,10e-3,45,45,38e9)

Pattern = RadiationPattern(AF,0:360,0:180,38e9)

plotPattern3D(Pattern,gainMin=-30)
