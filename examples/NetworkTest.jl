using Revise
using Marconi
using PGFPlotsX

function inductorAndResistor(L=1e-9,R=50;freq,Z0)
    z = R + im*2*pi*freq*L
    return (z-Z0)/(z+Z0)
end

freqs = 1e9:10e6:10e9

RL = EquationNetwork(1,50,inductorAndResistor)

plotRectangular(RL,(1,1),freqs=[100e6 200e6 300e6 400e6],args=(1e-9,35))

equationToDataNetwork(RL,args=(1e-9,50),freqs=Array(1e9:1e6:10e9))

ax = plotSmithData(RL,(1,1),freqs=1e9:10e6:10e9,args=(1e-9,30))

plotSmithData!(ax,RL,(1,1),freqs=1e9:10e6:10e9,args=(1e-9,90))

ax = plotRectangular(RL,(1,1),freqs=freqs,args=(1e-9,90))

plotRectangular!(ax,RL,(1,1),freqs=freqs,args=(1e-9,10))

ax = plotRectangular(RL,testK,args=(1e-9,30),freqs=Array(freqs))
