# Marconi.jl
A Julia Library for DC to Daylight

"Walks like Python, Runs like C" for open source RF/Microwave engineering.

## Main Features
Marconi.jl aims to give similar functionality as the wonderful scikit-rf
library in pure Julia. Most of this package will focus on linear network parameters
with more advanced non-linear network analysis coming in the future.

```@contents
Pages = [
    "man/FileIO.md",
    "man/NetworkAnalysis.md",
    "man/RFAnalysis.md",
    "man/Calibration.md",
    "man/Plot.md"
]
Depth = 1
```

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
If you use Marconi.jl in your work please cite us with something along the lines of

*Made possible with Marconi.jl, a Julia Library for DC to Daylight*

## In Presentations
Here is a nifty image you can use to show your support.
