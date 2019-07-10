# Network Analysis

```@contents
Pages = ["NetworkAnalysis.md"]
Depth = 3
```

## Converting Between Networks Representations
Marconi provides functionality to convert between S,Z,Y, and T Parameters. See the library for more details.

## Interpolations
To interpolate networks, one can just call `interpolate` with a network object and some
array or range of new frequencies. For evenly-spaced networks, `interpolate` will use a
cubic spline interpolation, while uneven spaced networks will use a standard linear gridded
interpolation.

```@eval
cd("../../..") # hide
cp("examples/Amp.s2p","docs/build/man/Amp.s2p", force = true) # hide
cp("examples/CE3520K3.s2p","docs/build/man/CE3520K3.s2p", force = true) # hide
nothing
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
Working with both data networks and equation driven networks can be tricky as mixing the two will always product a `DataNetwork`

Cascading any amount of equation-driven networks with a data network will always return a `DataNetwork`. Just as before,
the frequency of the result is the range that overlaps all the data networks or in the case of only one data network, the frequency range
of that network.

```@example cascade
function sillyFilter(f_center=1e9,rolloff=1;freq,Z0)
    s21 = f_center / (abs(freq-f_center)+f_center)*rolloff
    return [sqrt(1-s21^2)  s21;s21 sqrt(1-s21^2)]
end

filter = EquationNetwork(2,50,sillyFilter)

amp = readTouchstone("Amp.s2p")

net = cascade(amp,filter)

ax = plotRectangular(net,(2,1),label="Cascaded S(2,1)")
plotRectangular!(ax,amp,(2,1),label="Amplifier S(2,1)")
plotRectangular!(ax,filter,(2,1),freqs=net.frequency,label="Filter S(2,1)")
ax["ylabel"] = "dB"
ax # hide
```
