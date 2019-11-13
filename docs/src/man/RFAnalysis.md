# RF Analysis
```@contents
Pages = ["RFAnalysis.md"]
Depth = 3
```

```@eval
cd("../../..") # hide
cp("examples/CE3520K3.s2p","docs/build/man/CE3520K3.s2p", force = true) # hide
cp("examples/BPF.s2p","docs/build/man/BPF.s2p", force = true) # hide
nothing
```

## The Network Object
Marconi is structured around a base `AbstractNetwork` object. This object can be
constructed with data, equations, and the combination of other networks.

All networks provide attributes `ports` and `Z0` for characteristic impedance.

### DataNetwork
To build a network from a Touchstone file see [File IO](@ref), otherwise we can simply use the constructor for DataNetwork.

Besides `ports` and `Z0`, a `DataNetwork` must also have `frequency`, a vector of frequencies for which the network is characterized,
and `s_params`, for the S-Parameters themselves.

As of this release, the `frequency`/`s_params` lists must be ordered. If they are not
evenly-spaced, all interpolation operations will be Grid interpolations instead of splines.

```@example
using Marconi # hide
# DataNetwork(ports,Z0,frequency,s_params)
myNetwork = DataNetwork(1,50,[100e6, 200e6],[0.3+0.5im, 0.4+0.6im])
```

For more than 1 port, the S-Parameters have to be an n-square matrix for n ports.

```@example
using Marconi # hide
myNetwork = DataNetwork(2,50,[100e6, 200e6],[[0.3+0.5im 0.1+0.2im; 0.4+0.6im 0.3+0.5im], [0.3+0.5im 0.1+0.2im; 0.4+0.6im 0.3+0.5im]])
```

### EquationNetwork
To build a network from an equation, we start with an equation that defines some S-Parameters.

Take a series R-L network for example. The S-Parameters of an RL network would look like:

```@example 2
using Marconi # hide
function inductorAndResistor(;freq,Z0)
    L = 1e-9
    R = 30
    z = R + im*2*pi*freq*L
    return (z-Z0)/(z+Z0)
end
```

To use an equation-driven network in Marconi, the function must accept the kwags `freq` and `Z0`.

To build the `EquationNetwork`:

```@example 2
RL = EquationNetwork(1,50,inductorAndResistor)
```

Once again, for n-port networks, the function must provide an n-square matrix

```@example 2
function idealTransmissionLine(;freq,Z0)
    l = 1e-2 # 2cm
    λ = (3e8/freq)
    β = (2*pi)/λ
    return [0 exp(-β*l);exp(-β*l) 0]
end

tline = EquationNetwork(2,50,idealTransmissionLine)
```

## Stability Analysis

One of the most important aspects in active microwave design is that of stability.

When designing an amplifier, we do not want oscillations on either of the ports. An oscillation would imply that $|\Gamma_{In}| > 1$ or $|\Gamma_{Out}| > 1$.

As both of these gammas depend on the input and output matching networks, the stability of an amplifier depends on $\Gamma_{S}$ and $\Gamma_{L}$.

There are two different kinds of stability:
* Unconditional Stability - $|\Gamma_{In}| < 1$ and $|\Gamma_{Out}| < 1$ for all source and load impedances
* Conditional Stability - $|\Gamma_{In}| < 1$ and $|\Gamma_{Out}| < 1$ for certain impedances.

To test for unconditional stability, we can use the *Rollet Stability Criterion*

```math
K = \frac{1-|S_{11}|^2-|S_{22}|^2+|\Delta|^2}{2|S_{12}S_{21}|} > 1
```


along with the auxiliary condition that

```math
|\Delta| = |S_{11}S_{22}-S_{12}S_{21}| < 1
```

For a device to be unconditionally stable, both of these conditions must be satisfied.

Alternatively, the μ stability parameter is a similar test for unconditional stability that integrates all conditions into a single parameter.

```math
μ = \frac{1-|S_{11}|^2}{|S_{22}-\Delta S_{11}^{*}| + |S_{12}S_{21}|} > 1
```

To test these conditions (or plot them), use the following functions:

```@setup example_stab
using Marconi
using PGFPlotsX
```

*Example 12.2 from Microwave Engineering by David M. Pozar*
```@example example_stab
gan_hemt = [0.869*exp(deg2rad(-159)im) 4.250*exp(deg2rad(61)im);0.031*exp(deg2rad(-9)im) 0.507*exp(deg2rad(-117)im)]

network = DataNetwork(2,50,[1.9e9],[gan_hemt])
```
We now compute `|Δ|` with
```@example example_stab
testMagDelta(network)[1] # Only 1 point in this data
```

and `K` with
```@example example_stab
testK(network)[1]
```
So, now we can conclude that this device is *NOT* unconditionally stable at 1.9 GHz as $|\Delta| < 1 $,but $K<1$.

By calculating μ and testing the $\mu > 1$ stability condition a similar conclusion can be reached.

```@example example_stab
testμ(network)[1]
```

We can also plot the stability factors as a function of frequency to find stable regions.

Take the data from this CE3520K3 low noise JFET:

```@example example_stab
jfet = readTouchstone("CE3520K3.s2p")

# Plot our criteria
ax = plotRectangular(jfet,testK,label="K")
plotRectangular!(ax,jfet,testMagDelta,label=raw"$|\Delta|$")

# Add a horizontal line to show stability regions
push!(ax,@pgf(HLine(@pgf({"dashed"}),1)))

# Adjust legend location
ax["legend pos"] = "outer north east"

# And a title, why not
ax["title"] = "Stability Tests"

ax # hide
```

From this plot, we can conclude that under 50Ω matching on both ports,
this device is unconditionally stable from 14-18 GHz and above 25 GHz as those two regions satisfy the criterion.

### Stability Circles

To observe the behavior of potentially unstable devices, we can plot the region that would push the device into oscillation. The circle that bounds these impedances are *Stability Circles*.

To plot these stability circles we can start with a network at one frequency:

```@example example_stab
LNA = DataNetwork(2,50,[800e6],[[∠(0.65,-95) ∠(0.035,40); ∠(5,115) ∠(0.8,-35)]])
```

Now we can plot the the source and load stability circles on a smith chart.

```@example example_stab
sc = SmithChart()
plotSStabCircle!(sc,LNA,800e6,label="Source Stability")
plotLStabCircle!(sc,LNA,800e6,label="Load Stability")
```


## VSWR Circles

Some times it is helpful to draw VSWR circles to know the bandwidth of a network. This is done with

```@setup vswr
using Marconi
using PGFPlotsX
```

```@example vswr
# 10 dB RL == 1.92 VSWR
circleStyle = @pgf {"thick", color = "black"}
bpf = readTouchstone("BPF.s2p")
sc = plotSmithData(bpf,(1,1),label="S(1,1)")
plotVSWR!(sc,1.92,opts = circleStyle,label="VSWR = 1.92")
```

## Gain Equations
These functions provide calculations to asses the gain performance of active microwave circuits
### Maximum Unilateral Gain
Making the unilateral assumption, S12 = 0, we can calculate MUG as
```math
MUG = \frac{ |S_{21}|^2 }{ (1 - |S_{11}|^2)(1 - |S_{22}|^2) }
```
```@example example_stab
jfet = readTouchstone("CE3520K3.s2p")
plotRectangular(jfet,testMUG,dB,label="MUG")
```
### Maximum Stable Gain
The maximum gain out of a potentially unstable device
```math
MSG = \frac{ |S_{21}| }{ |S_{12}| }
```
```@example example_stab
jfet = readTouchstone("CE3520K3.s2p")
plotRectangular(jfet,testMSG,dB,label="MSG")
```
### Maximum Available Gain
Otherwise known as GMAX, MAG is the maximum gain from a stable network.
This formula comes from [Microwaves 101](https://www.microwaves101.com/encyclopedias/stability-factor) -
a modification from the textbook equation such that MAG behaves well for high K devices.
```math
MAG = \frac{ |S_{21}| }{ |S_{12}| } * \frac{1}{K+\sqrt{K^2-1}}
```
```@example example_stab
jfet = readTouchstone("CE3520K3.s2p")
plotRectangular(jfet,testMAG,dB,label="MAG")
```
This makes sense as looking at the K plot from before, the device is only unconditionally stable around 14 GHz and above 25 GHz.

Just to compare this to the S21 parameter:
```@example example_stab
ax = plotRectangular(jfet,testMAG,dB,label="MAG")
plotRectangular!(ax,jfet,(2,1),label="S(2,1)")
```

## Transmission Line Calculations
Marconi provides some basic calculations for transmission lines:

```@setup tline
using Marconi
```

```@example tline
# Input impedance of lossless t-line terminated in Zr
Θ = 35
Zr = 100+im*50
Zin = inputZ(Zr,Θ)
```

And to show the behavior we expect from a λ/4 line:
```@example tline
Θ = 89.99
Zr = 1e99+0im
Zin = inputZ(Zr,Θ)
```
