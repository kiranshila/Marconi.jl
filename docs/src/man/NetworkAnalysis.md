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
This network has 899 points from 10 MHz to 18 GHz. Let's reinterpret it to more points.

```@example interpolation
amp_morePoints = interpolate(amp,range(10e6,stop=18e9,length=1001))
```

As typical with interpolations, one can only interpolate between the bounds of the source data.

## Cascading Networks

### Cascading Data Networks with Equation-Driven Networks
