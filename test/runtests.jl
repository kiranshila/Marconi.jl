using Marconi, Test, PGFPlotsX
using PGFPlotsX: Options

if get(ENV, "CI", false) == true
    PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)
end

@show PGFPlotsX.latexengine
PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)

GNUPLOT_VERSION = try chomp(read(`gnuplot -V`, String)); catch; nothing; end
HAVE_GNUPLOT = GNUPLOT_VERSION ≠ nothing

@info "External binaries" PGFPlotsX.HAVE_PDFTOPPM PGFPlotsX.HAVE_PDFTOSVG GNUPLOT_VERSION

if !(PGFPlotsX.HAVE_PDFTOPPM && PGFPlotsX.HAVE_PDFTOSVG && HAVE_GNUPLOT)
    @warn "External binaries `pdf2svg`, `pdftoppm`, and `gnuplot` need to be installed
for complete test coverage."
end

include("test_networkanalysis.jl")
include("test_plots.jl")
include("test_marconicore.jl")

# Build the docs on Julia v1.1
if get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.1"
    cd(joinpath(@__DIR__, "..")) do
        withenv("JULIA_LOAD_PATH" => nothing) do
            cmd = `$(Base.julia_cmd()) --depwarn=no --color=yes --project=docs/`
            run(`$(cmd) -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'`)
            run(`$(cmd) docs/make.jl`)
        end
    end
end
