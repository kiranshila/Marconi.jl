using Marconi
using PGFPlotsX

function inductorAndResistor(;freq)
    x = 30 + im*2*pi*freq*1e-9
end

RL = EquationNetwork(1,30,inductorAndResistor)

plotSmithData(RL,(1,1),freqs=range(100e6,stop=100e9,length=201),opts=style,axopts=axstyle)

bpf = readTouchstone("examples/BPF.s2p")

axstyle = @pgf {width="20cm", title="Big Boi"}

style = @pgf {color = "red", "thick"}
plotSmithData(bpf,(1,1),opts=style)

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
