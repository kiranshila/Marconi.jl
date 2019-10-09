using Marconi
using PlotlyJS
using BenchmarkTools

freq = 70e6
λ = c₀/freq

AF = generateRectangularAF(2,2,1.5*λ,1.5*λ,0,0,freq)

Pattern = RadiationPattern(AF,0:360,-180:180,freq)

plotPattern3D(Pattern,gainMin=-30)



plotPattern3D(pattern)

AF = generateRectangularAF(10,10,0.1,0.1,0,0,2.4e9)

plotPattern3D(applyAF(pattern,AF,2.4e9),gainMin=-30)


Pattern = RadiationPattern(generateRectangularAF(4,4,λ/2,λ/2,45,45,freq),0:360,0:180,freq)


AF = generateCircularAF(100,5,0,0,1e9)
Pattern = RadiationPattern(AF,0:360,0:180,freq)
plt = plotPattern3D(Pattern,gainMin=-30)



trial = @benchmark readHFSSPattern("Patch.csv")
