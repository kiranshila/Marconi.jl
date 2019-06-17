using Marconi
using PGFPlotsX

bpf = readTouchstone("examples/Amp.s2p")

style1 = @pgf {color = "red", "thick"}
style2 = @pgf {color = "blue", "thick"}
style3 = @pgf {color = "green", "thick"}
style4 = @pgf {color = "yellow", "thick"}

ax = plotRectangular(bpf,(1,1),dB,opts = style1)
plotRectangular!(ax,bpf,(1,1),dB,opts = style2)
plotRectangular!(ax,bpf,(1,1),dB,opts = style3)
plotRectangular!(ax,bpf,(1,2),dB,opts = style4)
