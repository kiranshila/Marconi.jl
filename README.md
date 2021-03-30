<p align="center">
<img width="400px" src="https://raw.githubusercontent.com/kiranshila/Marconi.jl/master/docs/src/assets/logo_full.png"/>
</p>

# No longer being actively developed
Since authoring this package, I have grown a lot as a Julia developer. One of the things I now realize, is that large, monolithic packages aren't quite as usefull as smaller, more intentional ones. It is for that reason that I am deciding to no longer work on Marconi, and switch over to several smaller packages. The first of which will be Antennas.jl and Touchstone.jl. The existing Antenna functionality from Marconi will be moved to Antennas and updated with a few more features (as well as plot recipies). As far as I'm aware, a complete implementation of the Touchstone spec doesn't currently exist in Julia, for which I hope to implement in a registered package Touchstone.jl

If it makes sense, I may come back and unarchive Marconi if that seems to be the right place for network manipulation and plot recipies.

If anyone has any thoughts on this, shoot me a PM on reddit - /u/activexray

Best,
Kiran

[![][docs-dev-img]][docs-dev-url] [![][travis-img]][travis-url] [![][codecov-img]][codecov-url]

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://kiranshila.github.io/Marconi.jl/latest

[travis-img]: https://travis-ci.org/kiranshila/Marconi.jl.svg?branch=master
[travis-url]: https://travis-ci.org/kiranshila/Marconi.jl

[codecov-img]: https://codecov.io/gh/kiranshila/Marconi.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/kiranshila/Marconi.jl

*"Walks like Python, Runs like C" for open source RF/Microwave engineering*

```julia
julia> Pkg.add("Marconi")
```
