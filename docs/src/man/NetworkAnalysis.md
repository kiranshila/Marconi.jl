# Network Analysis

```@contents
Pages = ["NetworkAnalysis.md"]
Depth = 3
```

## Converting Between Networks Representations

## Interpolations
To interpolate networks, one can just call `interpolate` with a network object and some
array or range of new frequencies. For evenly-spaced networks, `interpolate` will use a
cubic spline interpolation, while uneven spaced networks will use a standard linear gridded
interpolation.

```@eval
cd("../../..") # hide
cp("examples/Amp.s2p","docs/build/man/Amp.s2p", force = true) # hide
cp("examples/CE3520K3.s2p","docs/build/man/CE3520K3.s2p", force = true) # hide
```

```@setup interpolation
using Marconi
using PGFPlotsX
```

```@example interpolation
# Uneven network
amp = readTouchstone("Amp.s2p")
```
This network has 879 points from 10 MHz to 18 GHz. Let's reinterpret it to more points.

```@example interpolation
amp_morePoints = interpolate(amp,range(10e6,stop=18e9,length=1001))
```

As typical with interpolations, one can only interpolate between the bounds of the source data.

## Cascading Networks
For working with 2-Port networks, cascading multiple networks can be helpful for finding system
performance, embedding, and deembedding.

`cascade` takes `n` number of 2-Port networks and returns a new `DataNetwork` that is the cascaded
result of all the networks. This function interpolates all networks to their overlapping frequency range,
converts to T-Parameters, and cascades with matrix multiplication.

```@setup cascade
using Marconi
using PGFPlotsX
```

Here are two networks individually, an amplifier and band-pass filter
```@example cascade
amp = readTouchstone("Amp.s2p")
bpf = readTouchstone("BPF.s2p")
ax = plotRectangular(amp,(2,1))
plotRectangular!(ax,bpf,(2,1))
```

And cascading Port 1 -> BPF -> Amp -> Port 2
```@example cascade
system = cascade(bpf,amp)
plotRectangular!(ax,system,(2,1))
```

### Cascading Data Networks with Equation-Driven Networks
