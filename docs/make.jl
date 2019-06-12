using Marconi, PGFPlotsX

makedocs(
    modules = [Marconi],
    format = Documenter.HTML(
        # Use clean URLs, unless built as a "local" build
        prettyurls = !("local" in ARGS),
        canonical = "https://kiranshila.github.io/Marconi.jl/stable/"
    ),
    clean = false,
    sitename = "Marconi.jl",
    authors = "Kiran Shila",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Guide" => "man/Guide.md",
            "man/FileIO.md",
            "man/NetworkAnalysis.md",
            "man/RFAnalysis.md",
            "man/Calibration.md",
            "man/Plot.md",
        ],
    ],
    strict = true,
)

@info "calling deploydocs"

deploydocs(
    repo = "github.com/kiranshila/Marconi.jl.git",
    target = "build",
)
