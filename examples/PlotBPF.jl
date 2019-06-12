using Revise
using PGFPlotsX
using Marconi

bpf = readTouchstone("examples/BPF.s2p")

axopts = @pgf {title="Hi", width = "5cm"}
pltopts = @pgf {color = "red"}

p = plotSmith(bpf,(1,1), axopts = axopts, pltopts = pltopts)
p = plotSmithCircle!(p,0.5,0.5,0.4)
