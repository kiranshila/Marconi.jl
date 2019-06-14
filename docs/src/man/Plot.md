# Plotting
!!! note

    The plotting library depends on a working installation of PGFPlotsX.jl

Currently, one can plot networks on
* Smith Charts
* Rectangular Plots
* Polar Plots

* Circles on Smith Charts
  * Gain Circles
  * Q Circles
  * VSWR Circles
  * Constant-R Circles
  * Constant-G Circles
  * Constant-X Circles
  * Constant-Y Circles

## Smith Charts

To start plotting on Smith Charts, it generally is a good idea to start with an
empty `SmithChart` axis object.

```julia
sc = SmithChart()
```

This object is a container for `Network` data as well as circles.

To push objects into this circle, one can use either `plotSmith!` or `plotSmithCircle!`.

In addition, one can generate a SmithChart from data or a circle with `plotSmith` and `plotSmithCircle`.

Lets add some data to this plot
