![Logo](assets/logo_full.svg)

*"Walks like Python, Runs like C" for open source RF/Microwave engineering*

## Main Features
Marconi.jl is a library for analysis and plotting of linear RF/Microwave networks, antenna calculations, and rudimentary metamaterial calculations.

It aims to give similar functionality as the wonderful [scikit-rf](https://scikit-rf-web.readthedocs.io/)
library in pure Julia while extending the use case to some antennas and metamaterials.

While focusing on linear network analysis now, we hope to implement some non-linear analysis
as well as instrument control in the future.

The main crux of this library presently is on plotting as the Smith Chart plotting backend is in the heavyweight PGFPlotsX. The antenna plots are being written with the wonderful PlotlyJS backend such that once I finish writing the Plotly Smith Chart type, I can transition this entire library to have fully interactive, lightweight, portable plots.

```@contents
Pages = [
    "man/RFAnalysis.md",
    "man/Plot.md",
    "man/FileIO.md",
    "man/NetworkAnalysis.md",
    "man/Antennas.md",
    "man/Metamaterials.md"
]
Depth = 1
```

## Library Outline

```@contents
Pages = ["lib/Public.md"]
```

# Coming Soon
Depending on the progress of some other libraries, Marconi.jl would like to include
in the near future
* Calibration
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
] add Marconi
```
or from Pkg itself
```julia
using(Pkg)
Pkg.add("Marconi")
```

## In Publications
If you use Marconi.jl in your work please cite us with something along the lines of

*Made possible with Marconi.jl, a Julia Library for DC to Daylight*
