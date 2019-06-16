# Plotting
!!! note

    The plotting library depends on a working installation of PGFPlotsX.jl

```@contents
Pages = ["Plot.md"]
Depth = 3
```

The core of the plotting functionality in Marconi comes from the `PGFPlotsX` backend.
This library allows for publication-quality graphics with complete configurability of
the layout itself.

The functions within the plotting library merely contextualize the `Network` object or
other parameters into a `PGFPlotsX` plot object.

It is highly recommended to thoroughly read the docs for `PGFPlotsX` to make the post of
its plotting capability.

## Smith Charts

To start plotting on Smith Charts, it generally is a good idea to start with an
empty `SmithChart` axis object from `PGFPlotsX`.

```@eval
cd("../../..") # hide
cp("examples/BPF.s2p","docs/build/man/BPF.s2p", force = true) # hide
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

## Polar Plots

## Groups of Plots
