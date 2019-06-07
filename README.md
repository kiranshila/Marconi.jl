# Marconi.jl
A Julia Library for DC to Daylight
"Walks like Python, Runs like C" for open source RF/Microwave engineering.

## Main Features
Marconi.jl aims to give similar functionality as the wonderful scikit-rf
library in pure Julia. Most of this package will focus on linear network parameters
with more advanced non-linear network analysis coming in the future.
### File IO
Marconi.jl supports reading and writing standard Touchstone files with most of
Touchstone spec implemented including N ports, non standard port impedances, and
S, Y, Z, H, and G parameter reading.

Marconi.jl currently does not support noise parameters nor per-port impedance.
### Network Analysis
Marconi.jl supports conversion between S, Y, Z, H, G, ABCD and T parameters.

There are functions to cascade networks and deembed networks as well.
### RF Analysis
Marconi.jl can calculate simple pasivisity and reciprocity calculations as well
as first principles including but not limited to:
* Rowlett Stability Analysis
* Maximum Gain
* Maximum Stable Gain
* Q-Factor

### Calibration
Marconi.jl supports calibration using the following methods
* SOL(R/T)
* TRL

Also implemented are textbook bilateral and unilateral transistor calculations.

## Plotting
Marconi.jl uses Plots.jl as the plotting framework with (currently) InspectDR as
the plotting backend.

Currently, one can plot
* Networks
** Smith Chart
** Rectangular Plots
** Polar Plots

* Circles on Smith Charts
** Gain Circles
** Q Circles
** VSWR Circles
** Constant-R Circles
** Constant-G Circles
** Constant-X Circles
** Constant-Y Circles

# Coming Soon
Depending on the progress of some other libraries, Marconi.jl would like to include
in the near future
* Instrument control
* Noise analysis
* Filter builders
* Simple network construction from ideal components
* Optimization of said networks
* Advanced calibration routines
* Non-linear analysis (X-Parameters, Load Pull, etc.)
* More interactivity with plots

# Using Marconi.jl
To use Marconi.jl simply use the Pkg REPL
```julia
] add https://github.com/kiranshila/Marconi.jl
```
or from Pkg itself
```julia
using(Pkg)
Pkg.add("https://github.com/kiranshila/Marconi.jl")
```

## In Publications
If you use Marconi.jl in your work please cite our work with something along the lines of
"Made possible with Marconi.jl, a Julia Library for DC to Daylight"

## In Presentations
Here is a nifty image you can use to show your support.
