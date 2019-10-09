using Marconi
using PlotlyJS

freq = 70e6
λ = c₀/freq

AF = generateRectangularAF(2,2,1.5*λ,1.5*λ,0,0,freq)

Pattern = RadiationPattern(AF,0:360,-180:180,freq)

plotPattern3D(Pattern,gainMin=-30)
