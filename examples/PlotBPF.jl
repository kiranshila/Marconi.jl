using Revise
using PGFPlotsX
using Marconi

bpf = readTouchstone("examples/BPF.s2p")

sc = SmithChart()

plotSmith!(sc,bpf,(1,1))
plotSmith!(sc,bpf,(2,2))

sc.contents[2]["color"] = "red"

plotSmithCircle!(sc,0.5,0.5,0.4,opts = @pgf({"very thick"}))

sc["title"] = "My Smith Chart"

sc
