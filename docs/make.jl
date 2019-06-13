using Marconi, PGFPlotsX, Documenter, DocumenterTools
PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)

makedocs(
    modules = [Marconi],
    clean = false,
    doctest = true,
    strict = true,
    checkdocs = :none,
    sitename = "Marconi.jl",
    authors = "Kiran Shila",
    linkcheck = !("skiplinks" in ARGS),
    pages = Any[
        "Home" => "index.md",
        "Manual" => [
            "man/FileIO.md",
            "man/NetworkAnalysis.md",
            "man/RFAnalysis.md",
            "man/Calibration.md",
            "man/Plot.md"],
        "Library" => Any[
            "Public" =>"lib/Public.md"]])

@info "calling deploydocs"

deploydocs(
    repo = "github.com/kiranshila/Marconi.jl.git",
    target = "build",
)
