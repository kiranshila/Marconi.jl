# Antennas

```@contents
Pages = ["Antennas.md"]
Depth = 3
```

```@eval
cd("../../..") # hide
cp("examples/Pattern.csv","docs/build/man/Pattern.csv", force = true) # hide
nothing
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

The patterns we can generate within Marconi are limited, so most of the pattern data will come from outside sources. Most of what I use this for is importing simulated data from HFSS. This format is a simple CSV file, following a ϕ,θ,gain format with phi swept first. One can bring in data from an antenna chamber with the same function, as long as the data is evenly sampled.

To read from a CSV file in this format, a la HFSS:

```@example rad
pattern = readHFSSPattern("Pattern.csv")
```

Notice that this will automatically calculate the range of the pattern in ϕ and θ and create the range objects for you.


### Plotting Radiation Patterns
We can plot these radiation patterns in 2D and 3D with the Plotly.js backend. These plots are fully interactive and the objects returned by these plot functions can be modified as typical PlotlyJS objects.

To plot a polar 2D plot, call the `plotPattern2D` function with the pattern and a `ϕ` to slice.

```@example rad
plt = plotPattern2D(pattern,90)
html_plot(plt) # hide
```

And to plot in 3D, call the `plotPattern3D` function.

```@example rad
plt = plotPattern3D(pattern,gainMin = -30)
html_plot(plt) # hide
```

Both of these functions utilize the `gainMin` and `gainMax` kwarg to set plotting bounds.


### Antenna Arrays and Array Factor
Another very important aspect of working with antennas, is utilizing multiple antennas to form an array. The mechanics of arrays are quite simple, and the analysis of the math can be found in any introductory antenna theory book.

In short, an array can be analyzed by first looking at the Array Factor. The Array Factor is the "Radiation Pattern" of an array with isotropic antennas located at certain positions with certain phasor excitations. This is useful as it removes the element pattern from the analysis so one can just evaluate the performance of the spacing and phasing itself.

To construct an array, one can provide the locations and excitations directly into the `ArrayFactor` constructor.

```@setup af
using Marconi
using PlotlyJS
```

```@example af
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
Pattern = RadiationPattern(AF,0:360,-180:180,1e9)
```

We can then plot this as if it were a regular `RadiationPattern`:

```@example af
plt = plotPattern2D(Pattern,0,gainMin=-30)
html_plot(plt) # hide
```

```@example af
plt = plotPattern3D(Pattern,gainMin=-30)
html_plot(plt) # hide
```

This is useful for general case arrays, but often we deal with rectangular arrays. A rectangular array can be created with the `generateRectangularAF` function. This requires a number of elements in x and y, the spacing in x and y (in meters), ϕ and θ for the direction of the beam (for a phased array), and a frequency to relate the phasing to the physical distance.

Lets create a broadside λ/2-spaced 4x4 square array for 5.8 GHz and plot it in 3D.

```@example af
freq = 5.8e9
λ = c₀/freq
AF = generateRectangularAF(4,4,λ/2,λ/2,0,0,freq)
Pattern = RadiationPattern(AF,0:360,0:180,freq)
plt = plotPattern3D(Pattern,gainMin=-30)
html_plot(plt) # hide
```

As expected from theory, we get no grating lobes. We can easily investigate the effect of greater spacing, say λ.

```@example af
AF = generateRectangularAF(4,4,λ,λ,0,0,freq)
Pattern = RadiationPattern(AF,0:360,0:180,freq)
plt = plotPattern3D(Pattern,gainMin=-30)
html_plot(plt) # hide
```

Once again, from theory, we now see grating lobes appear at θ=90. Now if we didn't want the array to be broadside, we can use the `generateRectangularAF` function to steer the array towards an arbitrary direction, say ϕ=45, θ=45.

```@example af
AF = generateRectangularAF(4,4,λ/2,λ/2,45,45,freq)
Pattern = RadiationPattern(AF,0:360,0:180,freq)
plt = plotPattern3D(Pattern,gainMin=-30)
html_plot(plt) # hide
```

If we want a circular array with the same number of elements to point in the same direction, we can use the `generateCircularAF` function.

```@example af
AF = generateCircularAF(16,λ,45,45,freq)
Pattern = RadiationPattern(AF,0:360,0:180,freq)
plt = plotPattern3D(Pattern,gainMin=-30)
html_plot(plt) # hide
```

### Applying Array Factors to Radiation Pattern Data
Analyzing the array factor by itself is useful as we can get insight into grating lobes, and some rudimentary gain analysis, but usually we want to investigate what our single element will look like in an array context.

The theory states that we can simply add the dBi array factor to our pattern measurement - assuming we feed the array with the excitations given in the array factor.

Marconi supplies a utility function to generate a `RadiationPattern` from the array factor with the same spherical steps as the pattern. Then it will add two patterns together and return a new `RadiationPattern`. Take the pattern from the beginning of this page for example. We can put it in a 2x2 array with 10mm spacing at 38 GHz, broadside phased.

```@example af
freq = 38e9
Pattern = readHFSSPattern("Pattern.csv")
AF = generateRectangularAF(2,2,10e-3,10e-3,0,0,freq)
ArrayPattern = applyAF(Pattern,AF,freq)
plt = plotPattern3D(ArrayPattern,gainMin=-30)
html_plot(plt) # hide
```


## Solving Radiation Patterns
