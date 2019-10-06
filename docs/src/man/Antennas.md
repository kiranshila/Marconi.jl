# Antennas

```@contents
Pages = ["Antennas.md"]
Depth = 3
```

## The Basics
Marconi provides an object for storing and handling radiation pattern data as an interface to working with antennas. This library doesn't intend to ever replace a full-wave solver, but hopefully will provide functions to get started with designing basic antennas and arrays.

To try to provide some semblance of consistency, most everything involving antennas will be in the order of $\phi$, $\theta$. This includes the indexing into array data. These angles are in degrees for all of the functions in Marconi.

### Radiation Patterns
This `RadiationPattern` object can be constructed in a few ways. The default constructor accepts a range or array of azimuth from the x-axis - $\phi$, the elevation towards -z from the z axis $\theta$, and a 2D matrix of the pattern data represented by those spherical points. This data matrix is stored in dBi, or dB above isotropic.

To construct an isotropic radiator, for example:

```@example rad
using Marconi

ϕ = 0:360
θ = 0:180
data = zeros(Float64,(length(ϕ),length(θ)))

isotropic = RadiationPattern(ϕ,θ,data)
```

The patterns we can generate within Marconi are limited, so most of the pattern data will come from outside sources. Most of what I use this for is importing simulated data from HFSS. This format is a simple CSV file, following a phi,theta,gain format with phi swept first. One can bring in data from an antenna chamber with the same function, as long as the data is evenly sampled.


### Plotting Radiation Patterns
We can plot these radiation patterns in 2D and 3D with the Plotly.js backend. These plots are fully interactive and the objects returned by these plot functions can be modified as typical PlotlyJS objects.

To plot a polar 2D plot, call the `plotPattern2D` function with the pattern and a `ϕ` to slice.

FIXME



### Antenna Arrays and Array Factor
Another very important aspect of working with antennas, is utilizing multiple antennas to form an array. The mechanics of arrays are quite simple, and the analysis of the math can be found in any introductory antenna theory book.

In short, an array can be analyzed by first looking at the Array Factor. The Array Factor is the "Radiation Pattern" of an array with isotropic antennas located at certain positions with certain phasor excitations. This is useful as it removes the element pattern from the analysis so one can just evaluate the performance of the spacing and phasing itself.

To construct an array, one can provide the locations and excitations directly into the `ArrayFactor` constructor.

```@example af
using Marconi

AF = ArrayFactor([(0,0,0),(1,1,1)],[∠(1,0),∠(1,35)])
```

This creates an array factor object for antennas located at (0,0,0) and (1,1,1) with excitations 1∠0 and 1∠35.

To evaluate the directivity of the Array Factor at a given spherical point, we perform the following calculation:

First we construct the steering vector
```math
V = e^{-jk \cdot r}
```
Where $r$ is the vector to each antenna location, and $k$ is the wave vector in spherical.

Given the vector of excitations, we simply dot the steering vector with the excitations to get linear directivity.

In Marconi, use the `ArrayFactor` functor to generate this at a given, `ϕ` and `θ`, and frequency `freq`.

```@example af
D = AF(45,45,1e9)
```

To work with the AF as a pattern, we can evaluate this AF functor at every phi and theta in a list by using the `RadiationPattern` constructor for an `ArrayFactor`.

```@example af
Pattern = RadiationPattern(AF,0:360,0:180,1e9)
```

We can then plot this as if it were a regular `RadiationPattern`:

```@example af
plotPattern2D(AF,0)
```

```@example af
plotPattern3D(AF,0)
```

## Solving Radiation Patterns
