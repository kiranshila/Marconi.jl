using Marconi
using PGFPlotsX

function inductorAndResistor(;freq,Z0)
    z = 30 + im*2*pi*freq*1e-9
    return [(z-Z0)/(z+Z0)]
end

RL = EquationNetwork(1,50,inductorAndResistor)

axstyle = @pgf {width="20cm", title="Big Boi"}

style = @pgf {color = "red", "thick"}

plotSmithData(RL,(1,1),freqs=range(100e6,stop=10e9,length=201),opts=style,axopts=axstyle)

bpf = readTouchstone("examples/BPF.s2p")



@pgf TikzPicture(
        Axis(
            PlotInc({ only_marks },
                Table(; x = 1:2, y = 3:4)),
            PlotInc(
                Table(; x = 5:6, y = 1:2))))

SmithChart()

using Pkg
using PGFPlotsX

Pkg.add("PGFPlotsX")

Pkg.build("PGFPlotsX")

function transmissionLine(;freq,Z0)
    l = 1e-2 # 2cm
    λ = (3e8/freq)
    β = (2*pi)/λ
    return [0 exp(-β*l);exp(-β*l) 0]
end
