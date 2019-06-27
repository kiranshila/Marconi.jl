using Revise
using Marconi
using PGFPlotsX

bpf = readTouchstone("examples/BPF.s2p")
amp = readTouchstone("examples/Amp.s2p")

ax = plotRectangular(amp,testK)

plotRectangular!(ax,amp,testMagDelta)
