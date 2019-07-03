using Marconi, PGFPlotsX, Documenter, DocumenterTools
PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)

makedocs(
    modules = [Marconi],
    clean = false,
    doctest = true,
    strict = false,
    checkdocs = :none,
    sitename = "Marconi.jl",
    authors = "Kiran Shila",
    linkcheck = !("skiplinks" in ARGS),
    pages = Any[
        "Home" => "index.md",
        "Manual" => [
            "man/RFAnalysis.md",
            "man/FileIO.md",
            "man/Plot.md",
            "man/NetworkAnalysis.md"],
        "Library" => Any[
            "Public" =>"lib/Public.md"]])

@info "calling deploydocs"

deploydocs(
    repo = "github.com/kiranshila/Marconi.jl.git",
    target = "build",
)
