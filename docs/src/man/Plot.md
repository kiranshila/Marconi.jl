# Plotting
!!! note

    The plotting library depends on a working installation of PGFPlotsX.jl and PlotlyJS.jl.
    Smith Charts are handled by PGFPlotsX while antennas and everything else are handled with Plotly. As soon as the PR is finished for Smith Charts, everything will transition to Plotly.

```@contents
Pages = ["Plot.md"]
Depth = 3
```

The core of the plotting functionality in Marconi comes from the `PGFPlotsX` and `PlotlyJS` backends.

These libraries allows for publication-quality graphics with complete configurability of
the layout itself.

The functions within the plotting library merely contextualize the `Network` object or
other parameters into a `PGFPlotsX` or `PlotlyJS` plot object.

It is highly recommended to thoroughly read the docs for `PGFPlotsX` and `PlotlyJS` to make the most of their plotting capabilities.

## Smith Charts

To start plotting on Smith Charts, it generally is a good idea to start with an
empty `SmithChart` axis object from `PGFPlotsX`.

```@eval
cd("../../..") # hide
cp("examples/BPF.s2p","docs/build/man/BPF.s2p", force = true) # hide
cp("examples/Amp.s2p","docs/build/man/Amp.s2p", force = true) # hide
nothing
```

```@example plot1
using Marconi
using PGFPlotsX
sc = SmithChart()
```

This object is an `Axis` which can accept `Plots` objects as well as `PGFPlotsX.Options`.

To push plot objects into this circle, one can use either `plotSmithData!` or `plotSmithCircle!`.

These functions create a `Plot` object out of `Network` data and adds them to an existing `Axis` object.

Lets add some data to this axis

```@example plot1
bpf = readTouchstone("BPF.s2p")
print(bpf) # hide
```
This is a network object of a BFCG-162W+ filter from MiniCircuits

We can now simply call `plotSmithData!` to write this data to the chart. The third
argument is a tuple of the parameter we want to plot. For this data, we want S(1,1),
so we pass in the `(1,1)` tuple.

```@example plot1
plotSmithData!(sc,bpf,(1,1))
```

This is the same behavior as if we constructed the axis and plotted simultaneously
with `plotSmithData`.

```@example plot1
plotSmithData(bpf,(1,1))
```

To add labels to any plot, we just call any of the plotting functions with the `label` kwarg.
```@example plot1
plotSmithData(bpf,(1,1),label="S(1,1)")
```

#### Plotting with Equation-Driven Networks
To plot with an `EquationNetwork`, we must also provide the frequencies to plot. This is done with the additional kwarg `freqs`.
We can also pass in arguments to our functions with the `args` kwarg.

```@example plot1
function inductorAndResistor(L=1e-9,R=30;freq,Z0)
    z = R + im*2*pi*freq*L
    return (z-Z0)/(z+Z0)
end
RL = EquationNetwork(1,50,inductorAndResistor)

ax = plotSmithData(RL,(1,1),freqs=range(100e6,stop=10e9,length=201))
plotSmithData!(ax,RL,(1,1),freqs=range(100e6,stop=10e9,length=201),args=(1e-9,50))
```

### Smith Chart Circles
As anyone who has read [Microwave Transistor Amplifiers](https://books.google.com/books/about/Microwave_Transistor_Amplifiers.html?id=bwpTAAAAMAAJ&source=kp_book_description) would know, drawing circles on a Smith Chart could be very useful. In `Marconi`, use cases such as stability circles and
gain circles are explored in [RF Analysis](@ref).

The `plotSmithCircle!` function behaves similarly to `plotSmithData` as it accepts a `SmithChart` object, x and y center coordinates, and
a radius.

These coordinates are referenced to the unit circle $\Gamma$ plane, so $-1 \leq x \leq 1$ and $-1 \leq y \leq 1$.

This *plot* can also accept the `opts` kwarg.

```@example plot1
sc = SmithChart()
style = @pgf {"color" = "cyan", "very thick"}
plotSmithCircle!(sc,0.3,0.75,0.3,opts = style)
```

### Plot Options
As these plots and axes are fundamentally `PGFPlotsX` objects, we can pass in options using the `opts` kwarg. Additionally, the `plotSmithData` function can take
a `axopts` kwarg to pass in options specific to the axis such as title and size.

```@example plot1
style = @pgf {color = "red", "thick"}
sc = plotSmithData(bpf,(1,1),opts = style)
```

The return of plotSmithData is a `SmithChart` axis object, so we can set variables after
the fact as well just like every other `PGFPlotsX` object.

```@example plot1
sc["title"] = "My Smith Chart"
```

Finally, the width and tick mark density is all related as per the PGFPlots manual.

Check it out [here](http://mirrors.ctan.org/graphics/pgf/contrib/pgfplots/doc/pgfplots.pdf)

When creating a `SmithChart` axis by itself, there is no kwarg for options.

```@example plot2
using PGFPlotsX # hide
axis_style = @pgf {width = "15cm",title = "Medium Smith Chart"}
sc = SmithChart(axis_style)
```

## Rectangular Plots

To plot on a rectangular axis, we simply call the `plot` function. `plot` by itself will plot S(1,1) in dB. The optional second positional argument is a tuple of the parameter to plot and the third optional argument is a function to map over the slice of the parameter in frequency.

```@setup example_rec
using Marconi
using PlotlyJS
```

```@example example_rec
amp = readTouchstone("Amp.s2p")
plt = plot(amp,(1,1),dB,name="S(1,1)")
plot!(plt,amp,(2,1),dB,name="S(2,1)")
html_plot(plt) # hide
```

Also, instead of supplying a tuple for the parameter to plot, one can supply a function to apply to the whole network. This function must take a `DataNetwork` as an argument and return a vector. There are several in this library for calculating stability, gain, and otherwise.
```@example example_rec
plt = plot(amp,testK)
html_plot(plt) # hide
```

#### Plotting with Equation-Driven Networks
